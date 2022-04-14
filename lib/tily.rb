module Tily
  MAX_STACK = 10_000
  TILES_EXPRESSION = /^{([\w\s]*)}$/
  COMMENT_EXPRESSION = /^\/\//
  TAG_EXPRESSION = /^\#(\w+)/
  COUNT_VALUE = "{N}"

  def self.execute(source)
    program = parse(source)
    program.execute
  end

  def self.parse(source)
    program = Program.new
    source.lines.each.with_index do |line, index|
      case line
      when TILES_EXPRESSION then program.tiles = $1.split.map(&:chars).flatten
      when TAG_EXPRESSION then program.tag $1
      when COMMENT_EXPRESSION # noop
      else program << Instruction.new(line, index + 1)
      end
    end
    program
  end

  class Program
    attr_reader :instructions, :tags, :memory
    attr_accessor :tiles
    
    def initialize
      @tiles = []
      @instructions = []
      @tags = {}
      @memory = {}
      @instruction_count = 0
      @cursor = 0
    end

    def execute
      while @cursor < @instructions.length do
        should_exit, value = *step_and_execute
        return value if should_exit
      end
    end

    def step
      if @cursor < @instructions.length
        should_exit, value = *step_and_execute
        return value if should_exit
      end
    end

    def step_and_execute
      @instruction_count += 1
      raise "MAX_STACK exceeded" if @instruction_count >= MAX_STACK          
      
      instruction = current_instruction
      case instruction.name
      when :ALLOCATE then
        @memory[instruction.args[0]] = nil
      when :ASSIGN then
        label = instruction.args[0]
        value = instruction.args[1]
        if value == COUNT_VALUE
          value = @tiles.count
        end
        @memory[label] = value
      when :COPY then
        value = @tiles[@memory[instruction.args[0]]]
        @memory[instruction.args[1]] = value
      when :INCREMENT then
        label = instruction.args[0]
        value = @memory[label]
        @memory[label] = value == "Z" ? "A" : value.next
      when :JUMP
        @cursor = @tags[instruction.args[0][TAG_EXPRESSION, 1]]
        return
      when :JUMP_IF_EQUAL
        if @memory[instruction.args[0]] == @memory[instruction.args[1]]
          @cursor = @tags[instruction.args[2][TAG_EXPRESSION, 1]]
          return
        end
      when :STOP then
        case instruction.args[0]
        when /yes/i then return [true, true]
        when /no/i then return [true, false]
        else return
        end
      end
      @cursor += 1

      [false, nil]
    end

    def current_instruction
      @instructions[@cursor]
    end

    def <<(instruction)
      @instructions << instruction
    end

    def tag(label)
      @tags[label] = @instructions.length
    end
  end

  class Instruction
    attr_reader :name, :args, :line
    def initialize(source, line)
      parts = source.split
      @name = parts.first.to_sym
      @args = parts[1..-1].map { |arg| arg =~ /^\d+$/ ? Integer(arg) : arg }
      @line = line
    end
  end
end