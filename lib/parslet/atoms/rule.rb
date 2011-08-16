
class Parslet::Atoms::Rule < Parslet::Atoms::Entity
  class MemoEntry < Struct.new(:ans, :pos)
    def error?
      self.ans.error?
    end
  end

  class LR < Struct.new(:pos, :detected)
    class Error < RuntimeError; end
    def ans
      self.detected = true
      raise Error
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

    # Eval rule body with LR supported by
    # placing a LR flag before eval rule body
    # and growing LR seed after detected LR
    def eval_rule_body_with_lr_support
      self.entry = lr = LR.new(pos)
      self.entry = eval_rule_body
      if lr.detected && !self.entry.error?
        grow_lr
      end
      self.entry
    end

    def eval_rule_body
      rewind
      ans = rule.eval_rule_body(source, context)
      MemoEntry.new(ans, source.pos)
    end

    private
    def rewind
      source.pos = self.pos
    end

    # Tries to grow the parse of rule at given position
    def grow_lr
      loop do
        entry = eval_rule_body
        break if entry.error? || entry.pos <= self.entry.pos
        self.entry = entry
      end
    end
  end

  alias_method :eval_rule_body, :try

  def try(source, context)
    position = Position.new(source.pos, source, context, self)
    entry = position.entry || position.eval_rule_body_with_lr_support
    source.pos = entry.pos
    entry.ans
  rescue LR::Error
    error(source, 'left recursion detected')
  end
end
