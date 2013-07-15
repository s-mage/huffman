#!/usr/bin/env ruby
#coding: utf-8
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
    return @left == nil && @right == nil
  end
end

# Generate an descending ordered aray of nodes with
# values [occurrences, character].
#
def occurrences(text)
  occ = Hash.new(0)
  text.scan (/./m) { |sym| occ[sym] += 1 }
  occ
end

# Convert hash to array of nodes.
#
def hash_to_nodes(hash)
  nodes = []
  hash.each_pair do
    |key, value| nodes << Node.new([key, value.to_i])
  end
  return nodes
end

# Sort array of nodes by key.
#
def sort_nodes(nodes)
  nodes.sort_by{|node| node.value.last}
end

# Huffman encoding itself.
#
# @param occlist [{symbol => occurence}] hash of symbols and their
# occurrences.
#
def huffman(occlist)
  # Build a Huffman encoding binary tree from the occurence list.
  #
  occlist =  hash_to_nodes(occlist)

  if occlist.empty?
    puts 'warning: no occurrences provided to build huffman tree'
    return nil
  end

  # Create the initial queue with nodes, trees contain assoc lists.
  #
  nodes = sort_nodes(occlist)
  deq = lambda { nodes.shift }

  # Create a new node from 2 shifted until the tree will not
  # contain all nodes. The tree will be full when it will be
  # alone is array of nodes.
  #
  while nodes.length > 1
    l, r = deq.call, deq.call
    node = Node.new([l.value[0] + r.value[0], l.value[1] + r.value[1]], l, r)
    nodes << node
    nodes = sort_nodes(nodes)
  end

  # Return built tree.
  #
  deq.call
end

# Create a hash { symbol => code } from Huffman tree and array
# of symbols.
#
def hash_code(huffman_tree, sym_array)
  sym_array.inject({}) do |result, sym|
    node = huffman_tree
    code = ''
    while  !(node.leaf?)
      if node.left.value[0].include?(sym)
        node = node.left
        code += '0'
      elsif node.right.value[0].include?(sym)
        node = node.right
        code += '1'
      end
    end
    result.merge(sym => code)
  end
end

# Decode text to original appearance with Huffman tree.
#
# @param ht [Node] Huffman tree.
# @param text [String] encoded text.
#
def decode(ht, text)
  node = ht
  out = ''
  text.scan /./m do |sym|
    case sym
      when '0'
        node = node.left
      when '1'
        node = node.right
    end

    if node.leaf?
      out << node.value[0]
      node = ht
    end
  end
  out
end

# Encode text to Huffman code with existing code.
#
# @param text [String] initial text.
# @param code [{ symbol => code }] hash of symbols and codes.
#
def encode(text, code)
  encoded_string = ''
  text.scan /./m do |sym|
    encoded_string += code[sym]
  end
  encoded_string
end

# Read file with occurences and put it into hash.
#
def file_to_hash(filename)
  Hash[*IO.binread(filename).split(' ')]
end

# Write hash with occurences to file.
#
def hash_to_file(hash, filename)
  str = ''
  hash.map { |key, value| str << key.to_s << ' ' << value.to_s << ' ' }
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
