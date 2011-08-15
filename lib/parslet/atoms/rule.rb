
class Parslet::Atoms::Rule < Parslet::Atoms::Entity
  def try(source, context)
    context.cache(self, source) {
      super(source, context)
    }
  end
end
