package require tcldbf
 
set file_name "books.dbf"
dbf d -create $file_name -codepage "LDID/201"
$d add bookText String 100
$d add bookName String 50
$d add author String 50
$d add date String 10

$d insert 0 "The Harry Potter Book" "Harry Potter" "Rowling J.K." "1997.06.26"
$d insert 1 "The Witcher's Book" "The Witcher" "Andrzej Sapkowski" "1993.01.01"
$d insert 2 "A Game of Thrones" "A Song of Ice and Fire" "George R.R. Martin" "1996.08.01" 
$d insert 3 "The Dexter Morgan Book" "Dexter's Slumbering Demon" "Jeffrey Lindsay" "2004.07.01"
$d insert 4 "A book about One Piece" "One Piece" "Eichiro Oda" "1997.08.04"
$d close
