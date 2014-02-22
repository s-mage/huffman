#!/usr/bin/env ruby
require 'optparse'

# Binary tree representation.  Node of binary tree consists of
# value and links to two childs: left and right. In this imple-
# mentation node is array [key, value], read about Huffman enco-
# ding to understand, why it is necessary.
#
class Node
  attr_accessor :value, :left, :right

  def initialize(value=nil, left=nil, right=nil)
    @value, @left, @right = value, left, right
  end

  # Is the current node leaf of tree? It means, that
  # node haven't childs.
  #
  def leaf?
    @left == nil && @right == nil
  end

  def in_left_brunch?(sym)
    left.symbols.include? sym
  end

  def in_right_brunch?(sym)
    right.symbols.include? sym
  end

  def occurrences
    value.occurrences
  end

  def symbols
    value.symbols
  end

  Value = Struct.new(:symbols, :occurrences)
end

# Generate an descending ordered aray of nodes with
# values [occurrences, character].
#
def occurrences(text)
  text.each_char.inject(Hash.new(0)) { |occ, x| occ[x] += 1; occ }
end

# Convert hash to array of nodes.
#
def to_nodes(hash)
  hash.inject([]) { |r, (k, v)| r << Node.new(Node::Value.new(k, v.to_i)) }
end

# Huffman encoding itself.
#
# @param occlist [{symbol => occurence}] hash of symbols and their
# occurrences.
#
def huffman(occlist)
  if occlist.empty?
    puts 'warning: no occurrences provided to build huffman tree'
    return nil
  end

  # Create queue of nodes, more occurrences -- lower position.
  nodes = to_nodes(occlist).sort_by(&:occurrences)
  tree(nodes)
end

# Create a new node from 2 shifted until the tree will not
# contain all nodes.
#
def tree(nodes)
  while nodes.length > 1
    l, r = nodes.shift, nodes.shift
    new_symbols = l.symbols + r.symbols
    new_occurrences = l.occurrences + r.occurrences
    new_value = Node::Value.new(new_symbols, new_occurrences)
    index = nodes.find_index { |x| x.occurrences > new_occurrences } || -1
    nodes.insert(index, Node.new(new_value, l, r)) # support nodes order.
  end
  nodes.first
end

# Create a hash { symbol => code } from Huffman tree and array
# of symbols.
#
def hash_code(huffman_tree, sym_array)
  sym_array.inject({}) do |result, sym|
    result.merge(sym => sym_code(huffman_tree, sym))
  end
end

def sym_code(huffman_tree, sym)
  code = ''
  node = huffman_tree.dup
  while !node.leaf?
    if node.in_left_brunch?(sym)
      code << '0'; node = node.left
    elsif node.in_right_brunch?(sym)
      code << '1'; node = node.right
    end
  end
  code
end

# Decode text to original appearance with Huffman tree.
#
# @param ht [Node] Huffman tree.
# @param text [String] encoded text.
#
def decode(ht, text)
  text.each_char.inject(['', ht]) do |(out, node), sym|
    case sym
    when '0' then next_node = node.left
    when '1' then next_node = node.right
    else raise 'Invalid code format'
    end
    next_node.leaf? ?
      [out << next_node.value[0], ht] :
      [out, next_node]
  end
end

# Encode text to Huffman code with existing code.
#
# @param text [String] initial text.
# @param code [{ symbol => code }] hash of symbols and codes.
#
def encode(text, code)
  text.each_char.inject('') { |r, x| r << code[x] }
end

# Read file with occurences and put it into hash.
#
def file_to_hash(filename)
  Hash[*IO.binread(filename).split(' ')]
end

# Write hash with occurences to file.
#
def hash_to_file(hash, filename)
  str = hash.inject('') { |r, (k, v)| r << "#{k.to_s} #{v.to_s} " }
  if filename == $stdout
    filename.write(str)
  else
    IO.binwrite(filename, str)
  end
end

text = <<TEXT
Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
Sed est nulla, suscipit vel, tempus sit amet, viverra sit amet, dui.
Nunc ultrices, purus vulputate luctus sodales, mauris augue elementum diam,
in ornare neque nisi pharetra lectus. In hac habitasse platea dictumst.
Phasellus justo turpis, laoreet id, semper at, convallis a, nisi. Duis iaculis
erat et mauris. Donec a arcu. Ut sed risus vel mi mollis vehicula. Aenean laoreet,
lorem dapibus aliquam ultrices, ante velit vestibulum sem, vel molestie arcu elit
sit amet nunc. Vivamus venenatis placerat dui. Mauris porttitor varius velit.
TEXT

hash_out = $stdout
text_out = $stdout
encoded_text = ''

# Algorirthm works bad if we don't replace newlines.
#
text.tr!(" \n", "\u{1 2}")

# Hash of all symbols and their occurrences.
#
hash_occurrences = occurrences(text)

opts = OptionParser.new do |opts|
  messages = { banner: 'Usage: huffman.rb [options]',
               t: 'Run program with your text TEXT',
               f: 'Run program with text in file FILE',
               occ_from_file: 'Run program with hash of occurrences in FILE',
               o: 'Choose output file',
               c: 'Choose file with encoding hash',
               e: 'Only encode text',
               d: 'Decode text',
               decodeff: 'Decode text from file',
               h: 'Show this message and exit'}
  opts.banner = messages[:banner]

  opts.on('-t', '--text TEXT', String, messages[:t]) do |txt|
    text = txt
    hash_occurrences = occurrences(text)
  end

  opts.on('-f', '--file FILE', messages[:f]) do |file|
    text = IO.read(file)
    hash_occurrences = occurrences(text)
  end

  opts.on('--occ_from_file FILE', messages[:occ_from_file]) do |file|
    hash_occurrences = file_to_hash(file)
  end

  opts.on('-o', '--out_file FILE', messages[:o]) do |file|
    text_out = File.open(file, mode='w+')
  end

  opts.on('-c', '--code_file FILE', messages[:c]) do |file|
    hash_out = File.open(file, mode='w+')
  end

  opts.on('-e', '--encode', messages[:e]) do
    ht = huffman(hash_occurrences) # huffman tree
    sym_array = hash_occurrences.keys # array of all symbols of the text
    p code = hash_code(ht, sym_array) # hash or all symbols and their codes
    encoded_text = encode(text, code) # encoded text
    text_out.write(encoded_text)
  end

  opts.on('-d', '--decode [TEXT]', messages[:d]) do |enc_text|
    text = enc_text || encoded_text
    ht = huffman(hash_occurrences)
    puts
    puts decoded_text = decode(ht, text).tr("\u{1 2}", " \n")  #decoded text
  end

  opts.on('--decodeff FILE', messages[:decodeff]) do |file|
    et = IO.binread(file)
    ht = huffman(hash_occurrences)
    puts decoded_text = decode(ht, et).tr("\u{1 2}", " \n")  #decoded text
  end

  opts.on_tail('-h', '--help', messages[:h]) do
    puts opts
    exit
  end

end.parse!
