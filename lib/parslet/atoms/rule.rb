
class Parslet::Atoms::Rule < Parslet::Atoms::Entity
  alias_method :eval_rule_body, :try

  def try(source, context)
    Position.new(source.pos, source, context, self).apply_rule
  end

  public :error
end

require 'parslet/atoms/rule/position'

