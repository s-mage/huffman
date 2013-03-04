Huffman
=======

Encoding/decoding with Huffman algorithm. Works with spaces and newlines, files and console.

Usage
=====

huffman.rb [options]

    -t, --text TEXT                  Run program with your text TEXT

    -f, --file FILE                  Run program with text in file FILE

        --occ_from_file FILE         Run program with hash of occurrences in FILE

    -o, --out_file FILE              Choose output file

    -c, --code_file FILE             Choose file with encoding hash

    -e, --encode                     Only encode text

    -d, --decode [TEXT]              Decode text

        --decodeff FILE              Decode text from file

    -h, --help                       Show this message and exit

Remember, that file huffman.rb must have rules to be executed. To give them, run
  
    chmod +x huffman.rb
