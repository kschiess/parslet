# Update/fetch parsed entry at a given position in source
# Eval rule body at a given position in source and cache the result
class Parslet::Atoms::Rule::Position < Struct.new(:pos, :source, :context, :rule)
  class MemoEntry < Struct.new(:answer, :pos)
    def error?
      self.answer.error?
    end
  end

  # A LR is info holder for left recursion
  #   seed: the last left recursion exp parse result
  #   rule: the rule starting left recursion
  #   head: when left recursion detected, head holds info to re-eval involved rules
  class LR < Struct.new(:seed, :rule, :pos, :head)
    class Head < Struct.new(:rule, :involved_rules, :eval_rules)
      def involved?(rule)
        self.rule == rule || self.involved_rules.include?(rule)
      end

      def eval?(rule)
        eval_rules.include?(rule)
      end

      def exclude_eval_rule!(rule)
        eval_rules.delete(rule)
      end

      def reset_eval_rules
        self.eval_rules = self.involved_rules.dup
      end
    end

    alias :answer :seed

    def detected?
      self.head != nil
    end

    def setup(lr_stack)
      self.head ||= Head.new(rule, [], [])
      lr_stack.top_down do |lr|
        return if lr.head == self.head
        lr.head = self.head
        self.head.involved_rules.push lr.rule
      end
    end
  end

  module Context
    def entry=(entry)
      context.set rule, pos, entry
    end

    def entry
      context.lookup(rule, pos)
    end

    def head
      context.heads[pos]
    end

    def head=(h)
      context.heads[pos] = h
    end

    def lr_stack
      context.lr_stack
    end
  end

  include Context

  # Eval rule body with LR supported by
  # placing a LR flag before eval rule body
  # and growing LR seed after detected LR
  def apply_rule
    result = recall
    if result.nil?
      lr = LR.new(fail('left recursion detected'), self.rule, self.pos)
      lr_stack.push(lr)
      self.entry = lr
      self.entry = eval_rule_body
      lr_stack.pop
      if !self.entry.error? && lr.detected?
        grow_lr(lr.head)
      end
      result = self.entry
    elsif result.is_a?(LR)
      result.setup(lr_stack)
    end
    source.pos = result.pos
    result.answer
  end

  private
  def recall
    # if not growing a seed parse, just return what is stored
    # in the memo table
    return self.entry if self.head.nil?
    # do not evaluate any rule that is not involved in this
    # left recursion
    # question: why self.entry.nil?
    if self.entry.nil? && !self.head.involved?(self.rule)
      return fail('not involved in head left recursion')
    end

    # allow involved rules to be evaluated, but only once
    # during a seed-growing iteration
    if self.head.eval?(self.rule)
      self.head.exclude_eval_rule!(self.rule)
      self.entry = eval_rule_body
    end
    self.entry
  end

  # Tries to grow the parse of rule at given position
  def grow_lr(h)
    self.head = h
    loop do
      h.reset_eval_rules
      entry = eval_rule_body
      break if entry.error? || entry.pos <= self.entry.pos
      self.entry = entry
    end
    self.head = nil
  end

  def fail(message)
    MemoEntry.new(rule.error(source, message), self.pos)
  end

  def eval_rule_body
    source.pos = self.pos
    answer = rule.eval_rule_body(source, context)
    MemoEntry.new(answer, source.pos)
  end
end