proc searchName {data bookName} {
    set matches {}
      foreach name $data {
            if {[string match -nocase $bookName* $name]} {
                  lappend matches $name
            } else {
                  puts "not found"
            } 
            
      }
      return "results: $matches"
}