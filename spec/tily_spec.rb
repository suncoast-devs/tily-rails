require 'tily'

RSpec.describe "Tily" do
  let(:source) {
    <<~EOF
      // This is a comment
      STOP yes
    EOF
  }

  let(:tagged_source) {
    <<~EOF
      ALLOCATE count
      ALLOCATE max
      ASSIGN count 0
      ASSIGN max 4
      #LOOP_BEGIN
      INCREMENT count
      JUMP_IF_EQUAL count max #EXIT
      JUMP #LOOP_BEGIN
      #EXIT
      STOP YES
    EOF
  }

  it "parses" do
    expect(Tily.parse(source)).to be_a Tily::Program
  end

  it "has instructions" do
    program = Tily.parse(source)
    expect(program.instructions).to_not be_empty
    expect(program.instructions.first).to be_a Tily::Instruction
  end

  it "ignores comments" do
    program = Tily.parse(source)
    expect(program.instructions.count).to eq(1)
  end

  it "tags instructions" do
    program = Tily.parse(tagged_source)
    expect(program.instructions.count).to eq(8)
    expect(program.tags["LOOP_BEGIN"]).to eq(4)
  end

  it "executes" do
    expect(Tily.execute(source)).to be_truthy
  end

  it "executes with a false return value" do
    expect(Tily.execute("STOP no")).to be_falsey
  end

  it "allocates memory" do
    program = Tily.parse("ALLOCATE count")
    program.execute
    expect(program.memory).to have_key("count")
  end

  it "assigns memory" do
    program = Tily.parse("ALLOCATE count\nASSIGN count 42")
    program.execute
    expect(program.memory["count"]).to eq(42)
  end

  it "increments an integer" do
    program = Tily.parse("ALLOCATE count\nASSIGN count 6\nINCREMENT count")
    program.execute
    expect(program.memory["count"]).to eq(7)
  end

  it "increments a letter" do
    program = Tily.parse("ALLOCATE count\nASSIGN count J\nINCREMENT count")
    program.execute
    expect(program.memory["count"]).to eq("K")
  end

  it "jumps to a tag while executing" do
    expect(Tily.execute("JUMP #EXIT\nSTOP no\n#EXIT\nSTOP yes")).to be_truthy
  end
  
  it "jumps if equal" do
    program = Tily.parse(tagged_source)
    program.execute
  end

  it "reads the tiles out of a program" do
    program = Tily.parse("{A B C D}")
    expect(program.tiles).to eq(["A", "B", "C", "D"])
  end

  it "can copy a tile to memory" do
    source = <<~EOF
      {DFG   RA FSD}
      ALLOCATE position
      ASSIGN position 4
      ALLOCATE letter
      COPY position letter
    EOF
    program = Tily.parse(source)
    program.execute
    expect(program.memory["letter"]).to eq("A")
  end

  it "handles N as a count of tiles" do
    source = <<~EOF
      {HJKL}
      ALLOCATE count
      ASSIGN count {N}
    EOF
    program = Tily.parse(source)
    program.execute
    expect(program.memory["count"]).to eq(4)
  end

end