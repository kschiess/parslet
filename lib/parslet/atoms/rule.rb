
class Parslet::Atoms::Rule < Parslet::Atoms::Entity
  class MemoEntry < Struct.new(:answer, :pos)
    def error?
      self.answer.error?
    end

    def result(lr_stack)
      if self.answer.is_a?(LR)
        self.answer.setup_lr(lr_stack)
        self.answer.answer
      else
        self.answer
      end
    end
  end

  class LR < Struct.new(:seed, :rule, :head, :next)
    def head_rule?(rule)
      self.head && self.head.rule == rule
    end

    def answer
      seed
    end

    def setup_lr(lr_stack)
      if self.head.nil?
        self.head = Head.new(rule, [], [])
      end
      s = lr_stack
      while(s.head != self.head) do
        s.head = self.head
        self.head.involved_rules.push s.rule
        s = s.next
      end
    end
  end

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
  end

  # Update/fetch parsed entry at a given position in source
  # Eval rule body at a given position in source and cache the result
  class Position < Struct.new(:pos, :source, :context, :rule)
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

      def push_into_lr_stack(lr)
        lr.next = context.lr_stack
        context.lr_stack = lr
      end

      def pop_lr_stack
        context.lr_stack = context.lr_stack.next
      end
    end
    include Context

    def apply_rule
      recall
      self.entry || eval_rule_body_with_lr_support
    end

    # Eval rule body with LR supported by
    # placing a LR flag before eval rule body
    # and growing LR seed after detected LR
    def eval_rule_body_with_lr_support
      with_lr_flag { self.entry = eval_rule_body }
      self.entry
    end

    def eval_rule_body
      rewind
      answer = rule.eval_rule_body(source, context)
      MemoEntry.new(answer, source.pos)
    end

    private
    def rewind
      source.pos = self.pos
    end

    def fail(message)
      MemoEntry.new(rule.error(source, message), source.pos)
    end

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
        self.eval_rule_body_with_lr_support
      end
      self.entry
    end

    def with_lr_flag
      lr = LR.new(rule.error(source, 'left recursion detected'), self.rule)
      push_into_lr_stack(lr)
      self.entry = MemoEntry.new lr, self.pos
      yield
      pop_lr_stack

      return if self.entry.error?
      grow_lr(lr.head) if lr.head_rule?(rule)
    end

    # Tries to grow the parse of rule at given position
    def grow_lr(h)
      self.head = h
      loop do
        h.eval_rules = h.involved_rules.dup
        entry = eval_rule_body
        break if entry.error? || entry.pos <= self.entry.pos
        self.entry = entry
      end
      self.head = nil
    end
  end

  alias_method :eval_rule_body, :try

  def try(source, context)
    position = Position.new(source.pos, source, context, self)
    entry = position.apply_rule
    source.pos = entry.pos
    entry.result(context.lr_stack)
  end

  public :error
end
