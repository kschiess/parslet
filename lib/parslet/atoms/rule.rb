
class Parslet::Atoms::Rule < Parslet::Atoms::Entity
  class MemoEntry < Struct.new(:ans, :pos)
    def error?
      self.ans.error?
    end

    def result(lr_stack)
      if self.ans.is_a?(LR)
        self.ans.setup_lr(lr_stack)
        self.ans.ans
      else
        self.ans
      end
    end
  end

  class LR < Struct.new(:rule, :seed, :head, :next)
    class Error < RuntimeError; end

    def detected?
      !self.head.nil?
    end

    def error?
      detected?
    end

    def ans
      raise Error.new('left recursion detected') if seed.nil?
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
    def evaluated?(rule)
      eval_rules.include?(rule)
    end
  end

  # Update/fetch parsed entry at a given position in source
  # Eval rule body at a given position in source and cache the result
  class Position < Struct.new(:pos, :source, :context, :rule)
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

    def apply_rule
      self.recall || self.eval_rule_body_with_lr_support
    end

    # Eval rule body with LR supported by
    # placing a LR flag before eval rule body
    # and growing LR seed after detected LR
    def eval_rule_body_with_lr_support
      lr = LR.new(rule)
      push_into_lr_stack(lr)
      self.entry = MemoEntry.new lr, self.pos
      eval_result = eval_rule_body
      pop_lr_stack
      self.entry.pos = eval_result.pos
      if lr.detected?
        lr.seed = eval_result.ans
        lr_answer
      else
        self.entry = eval_result
      end
      self.entry
    end

    def lr_answer
      h = self.entry.ans.head
      if h.rule != rule
        self.entry.ans = self.entry.ans.seed
      else
        self.entry.ans = self.entry.ans.seed
        unless self.entry.error?
          grow_lr(h)
        end
        self.entry
      end
    end

    def eval_rule_body
      rewind
      ans = rule.eval_rule_body(source, context)
      MemoEntry.new(ans, source.pos)
    end

    def recall
      # if not growing a seed parse, just return what is stored
      # in the memo table
      return self.entry if self.head.nil?
      # do not evaluate any rule that is not involved in this
      # left recursion
      if self.entry.nil? && !self.head.involved?(self.rule)
        raise LR::Error.new('not involved rule')
      end
      
      # allow involved rules to be evaluated, but only once
      # during a seed-growing iteration
      if self.head.evaluated?(self.rule)
        self.head.eval_rules.delete(self.rule)
        self.eval_rule_body_with_lr_support
      end
      self.entry
    end

    private
    def rewind
      source.pos = self.pos
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
  rescue LR::Error => e
    error(source, e.message)
  end
end
