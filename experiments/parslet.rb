$:.unshift File.dirname(__FILE__) + "/../lib"
require 'parslet'

# A smalltalk grammar from https://github.com/rkh/Reak (R. Konstantin Haase)
#
class AnsiSmalltalk < Parslet::Parser
  module NamedWithDefaults
    append_features Parslet::Atoms::Named
    attr_reader :defaults
    def with(opts)
      (@default ||= {}).merge! opts
      def self.produce_return_value(*)
        @default.merge super
      end
      self
    end
  end

  root :statements

  ##
  # Allows writing
  #   `foo`
  # instead of
  #   str('foo')
  alias_method :`, :str

  ##
  # Different Smalltalk dialects support different meta data tags in different places,
  # this method helps defining them. For instance, in Squeak, you can use:
  #
  #   rule(:primitive) { meta_data `primitive`, decimal }
  def meta_data(keyword, type = literal)
    `<` >> keyword >> `:` >> space? >> type >> space? >> `>`
  end

  ##
  # List of keywords. Dialects can easily add keywords by overriding this method.
  def keywords
    [`true`, `false`, `nil`, `self`, `super`]
  end

  ##
  # Smalltalk syntax definition.
  rule :space do
    match['\s'].repeat(1) 
  end

  rule :space? do
    space.maybe 
  end

  rule :letter do
    match['A-Za-z'] 
  end

  rule :digit do
    match['\d'] 
  end

  rule :comment do
    `"` >> (`""` | `"`.absnt? >> any).repeat >> `"` 
  end

  rule :separator do
    (comment | space).repeat(1) 
  end

  rule :separator? do
    separator.maybe 
  end

  rule :reserved_identifier do
    keywords.inject(:|).as(:reserved) 
  end

  rule :identifier do
    letter >> (letter | digit | `_`).repeat 
  end

  rule :capital_identifier do
    match['A-Z'] >> (letter | digit).repeat 
  end

  rule :bindable_identifier do
    reserved_identifier.absnt? >> identifier 
  end

  rule :decimal do
    `-`.maybe >> digit.repeat(1) 
  end

  rule :radix do
    decimal.as(:radix) >> `r` >> ((digit | letter).repeat(1)).as(:value)
  end

  rule :integer do
    (radix | decimal.as(:value).with(:radix => '10')).as :integer
  end

  rule :normal_float do
    decimal >> `.` >> digit.repeat(1) 
  end

  rule :scientific_float do
    (normal_float | integer).as(:base) >> match['edq'] >> integer.as(:power)
  end

  rule :float do
    (scientific_float | (normal_float).as(:base).with(:power => '0')).as(:float)
  end

  rule :scaled_decimal do
    ((decimal.as(:major) >> (`.` >> digit.repeat(1).as(:minor)).maybe).as(:mantissa) >> `s` >> decimal.as(:digits)).as(:scaled_decimal)
  end

  rule :number do
    scaled_decimal | float | integer 
  end

  rule :string do
    `'` >> (`''` | `'`.absnt? >> any).repeat.as(:string) >> `'`
  end

  rule :special do
    `+` | `*` | `/` | `\\` | `~` | `<` | `>` | `=` | `@` | `%` | `&` | `?` | `!` | `\`` | `,` | `|` 
  end

  rule :binary_selector do
    (`-`.repeat(1) | special) >> special.repeat 
  end

  rule :keyword do
    (identifier >> `:`).as(:keyword)
  end

  rule :symbol do
    (keyword.repeat(1) | identifier | binary_selector | string).as(:symbol)
  end

  rule :symbol_constant do
    `#` >> symbol 
  end

  rule :character_constant do
    `$` >> any.as(:character)
  end

  rule :array do
    list = number | symbol_constant | symbol | string | character_constant | array_constant | array
    `(` >> (list.as(:entry) | separator).repeat.as(:array) >> `)`
  end

  rule :array_constant do
    `#` >> array 
  end

  rule :literal do
    character_constant | number | symbol_constant | string | array_constant | reserved_identifier
  end

  rule :variable_name do
    bindable_identifier.as(:var)
  end

  rule :primary do
    literal | block | brace_expression | (`(` >> expression >> `)`) | variable_name 
  end

  rule :assignment do
    variable_name >> separator? >> (`:=` | `_`) 
  end

  rule :message_expression do
    keyword_expression | binary_expression | unary_expression
  end

  rule :keyword_send do
    (separator? >> keyword >> separator? >> binary_object.as(:value)).repeat(1).as(:send).with(:type => :keyword).as(:call)
  end

  rule :keyword_expression do
    (binary_object.as(:on) >> keyword_send.as(:send).with(:type => :direct)).as(:call)
  end

  rule :binary_send do
    (binary_selector.as(:selector) >> separator? >> unary_object.as(:value)).as(:send).with(:type => :binary).as(:call)
  end

  rule :binary_expression do
    (unary_object.as(:on) >> (separator? >> binary_send).repeat(1).as(:send).with(:type => :chain)).as(:call)
  end

  rule :unary_send do
    (identifier.as(:selector) >> (`:` | letter | digit).absnt?).as(:send).with(:type => :unary).as(:call)
  end

  rule :unary_expression do
    (primary.as(:on) >> (separator? >> unary_send).repeat(1).as(:send).with(:type => :chain)).as(:call)
  end

  rule :binary_object do
    binary_expression | unary_object 
  end

  rule :unary_object do
    unary_expression | primary 
  end

  rule :message_send do
    keyword_send | binary_send | unary_send 
  end

  rule :cascaded_message_expression do
    (message_expression.as(:on) >> (`;` >> separator? >> message_send).repeat(1).
      as(:send).with(:type => :unbalanced_cascade)).as(:call)
  end

  rule :brace_expression do
    `{` >> separator? >> (expressions >> separator? >> expression.maybe).as(:array) >> separator? >> `.`.maybe >> separator? >> `}`
  end

  rule :normal_expression do
    separator? >> (cascaded_message_expression | message_expression | primary) >> separator? 
  end

  rule :assignment_expression do
    (separator? >> assignment.as(:target) >> normal_expression.as(:value)).as(:assign)
  end

  rule :expression do
    # since everything is parsed into hashes, create expr nodes to force order
    # they'll get removed later
    (assignment_expression | normal_expression).as(:expr) 
  end

  rule :expressions do
    (expression >> `.`).repeat >> expression.maybe 
  end

  rule :statements do
    (expressions >> separator? >> (`^` >> expression >> `.`.maybe).as(:return).as(:expr).maybe).as(:expr)
  end

  rule :block do
    `[` >> separator? >> (block_arguments.maybe.as(:args) >> separator? >> code_body.as(:body)).as(:closure)  >> `]` 
  end

  rule :block_arguments do
    ((separator? >> `:` >> variable_name >> separator?).repeat(1) >> `|`)
  end

  rule :locals do
    (`|` >> separator? >> (variable_name >> separator?).repeat >> `|`)
  end

  rule :code_body do
    locals.maybe.as(:locals) >> statements.as(:code)
  end

  rule :method_header do
    keyword_method_header | binary_method_header | unary_method_header 
  end

  rule :keyword_method_header do
    keyword_argument >> (separator? >> keyword_argument).repeat 
  end

  rule :keyword_argument do
    keyword >> separator? >> variable_name 
  end

  rule :binary_method_header do
    binary_selector >> separator? >> variable_name 
  end

  rule :unary_method_header do
    bindable_identifier 
  end
end

AnsiSmalltalk.new.parse(
  File.read(ARGV.first || 'test.st'))
