class Node
    # binary tree representation
    attr_accessor :value, :left, :right
    def initialize(value=nil, left=nil, right=nil)
        @value, @left, @right = value, left, right
    end

    def leaf?
        return @left == nil && @right == nil
    end
end

def occurrences(text)
    # return an ordered array of nodes with values [occurrences, character] descending order
    occ = Hash.new(0)
    text.scan (/./m) { |sym| occ[sym] += 1 } 
    occ
end

def hash_to_nodes(hash)
  #convert hash to array of nodes
  nodes = []
  i = 0
  hash.each_pair do 
    |key, value| nodes[i] = Node.new([key, value])
    i += 1
  end
  return nodes
end

def sort_nodes(nodes)
  #sort array of nodes by keys
  nodes.sort_by{|node| node.value[1]}
end

def huffman(occlist)
    occlist =  hash_to_nodes(occlist)
    # build a huffman encoding binary tree from the occurance list
    if occlist.empty? then
        puts "warning: no occurrences provided to build huffman tree"
        return nil
    end

    # create the initial queue with leaves, trees contain assoc lists
    leaves = sort_nodes(occlist)
    deq = lambda { leaves.shift }

    # create new node instead 2 shifted
    while leaves.length > 1
        l, r = deq.call, deq.call
        node = Node.new([l.value[0] + r.value[0], l.value[1] + r.value[1]], l, r)
        leaves << node
        leaves = sort_nodes(leaves)
    end

    deq.call
end

def hash_code(huffman_tree, sym_array)
  #create a hash with symbols of sym_array and their codes
  code =  {}
  sym_array.map do |sym|
    node = huffman_tree
    code[sym] = '';
    while  !(node.leaf?) 
      if node.left.value[0].include?(sym)
        node = node.left
        code[sym] += '0'
      elsif node.right.value[0].include?(sym) 
        node = node.right
        code[sym] += '1'
      end
    end
  end
  code
end
  

def decode(ht, text)
  #decoding string text to original appearance with tree ht
  node = ht
  out = ""
   text.scan /./m do |sym|
    if node.leaf? 
      out += node.value[0]
      node = ht
    end

    case sym 
        when "0" 
          node = node.left
        when "1" 
          node = node.right
    end
  end
    out
end

def encode(text, code)
  #encoding string text to huffman code with hash code
  encoded_string = ''
   text.scan /./m do |sym|
    encoded_string += code[sym]
  end
  encoded_string
end


if $0 == __FILE__

text = <<TEXT
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed est nulla, suscipit vel, tempus sit amet, viverra sit amet, dui. Nunc ultrices, purus vulputate luctus sodales, mauris augue elementum diam, in ornare neque nisi pharetra lectus. In hac habitasse platea dictumst. Phasellus justo turpis, laoreet id, semper at, convallis a, nisi. Duis iaculis erat et mauris. Donec a arcu. Ut sed risus vel mi mollis vehicula. Aenean laoreet, lorem dapibus aliquam ultrices, ante velit vestibulum sem, vel molestie arcu elit sit amet nunc. Vivamus venenatis placerat dui. Mauris porttitor varius velit. 
TEXT

hash_occurrences = occurrences(text) #hash of all symbols and their occurrences
ht = huffman(hash_occurrences) #huffman tree
sym_array = hash_occurrences.keys #array of all symbols of the text
code = hash_code(ht, sym_array) #hash or all symbols and their codes
p encoded_text = encode(text, code) #encoded text


orig = text.length
new = encoded_text.length / 8.0
printf("original %s bytes, huffman encoded: %s bytes, ratio: %.2f%%", 
    orig, new, new/orig*100)
puts

p decoded_text = decode(ht, encoded_text) #decoded text
end
