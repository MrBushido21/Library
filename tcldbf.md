# tcldbf2 

Tcl package for accessing dbase files.
This package is an interface to the DFB functions of the [shapelib library](http://shapelib.maptools.org).
At the tcl script level, this library is compatible with [tcldbf package](https://geology.usgs.gov/tools/metadata/tcldbf/) with some fixes and extensions.

## LOADING

+       **package require tcldbf**

This command adds the **dbf** command to the tcl interpreter.
The **dbf** command is used to create or open a DBF file.

+       **package require dbf**

Same command, v.1 syntax.

## DBF SYNTAX:

+       **dbf <varname> open <dbf-file> ?-readonly?**

Opens dbase file and creates new tcl *command* to access file content.
New *command* name is assigned to the variable *varname*.
Returns new *command* name.

dbf *varname* create *dbf-file* ?-codepage *dbf-codepage*?

Creates empty dbase file.
Optional codepage can be specified as string LDID/*code* (see codepage table below). 

  dbf *varname* -open *dbf-file* ?-readonly?
  dbf *varname* -create *dbf-file* ?-codepage *dbf-codepage*?

Opens or creates dbase file, creates new tcl *command* in compatibility mode.
Returns 1 on success, 0 on failure.

## COMMAND SYNTAX:

  *command* codepage

    Returns database codepage.

  *command* info ?records|fields?

    Returns the number of records or fields.
    If the optional parameter is not specified, returns a list of two elements - the number of records and the number of fields

  *command* add *label* type|nativetype *width* ?prec?

    Adds field specified to the empty dbase file.
    Returns field index.

  *command* fields|field ?label?

    Returns dbase field description as a list of field's label, type, native type, width and precision.
    If optional parameter is not given, returns a list of all fields descriptions.
    If the optional parameter is not specified, returns a list of all field descriptions.

  *command* record *rowid*

    returns a list of cell values for the given row

  *command* get *rowid* ?label?

    returns a cell value for the given row or dictionary of cells

  *command* values *label*

    returns a list of values of the field $name

  *command* insert *rowid*|end *list*|?*value* ...?

    inserts the specified values into the given record

  *command* update *rowid*|end ?*field* *value*? ?*field* *value* ...?

    replaces the specified values of a single field in the record

  *command* deleted rowid ?mark?

        returns or sets the deleted flag for the given rowid

  *command* close
  *command* forget

        closes dbase file

## FIELD TYPES

| Type     | Nativetype  | Width | Prec     |
|:---------|:-----------:|:------|:---------|
| String   |     C       | 1-255 | 0        |
| Integer  |     N,F     | 1-9   | 0        |
| Double   |     N,F     | 1-255 | 1..width |
| Logical  |     L       | 1     | 0        |
| Date     |     D       | 8     | 0        |

## CODEPAGES

| Encoding      | Code  | Description                   |
|:--------------|:-----:|:------------------------------|	
| cp437		| 1	| US MS-DOS			|
| cp850		| 2	| International MS-DOS		|
| cp1252	| 3	| Windows ANSI Latin I		|
| macCentEuro	| 4	| Standard Macintosh		|
| cp865		| 8	| Danish OEM			|
| cp437		| 9	| Dutch OEM			|
| cp850		| 10	| Dutch OEM			|
| cp437		| 11	| Finnish OEM			|
| cp437		| 13	| French OEM			|
| cp850		| 14	| French OEM			|
| cp437		| 15	| German OEM			|
| cp850		| 16	| German OEM			|
| cp437		| 17	| Italian OEM			|
| cp850		| 18	| Italian OEM			|
| cp932		| 19	| Japanese Shift-JIS		|
| cp850		| 20	| Spanish OEM			|
| cp437		| 21	| Swedish OEM			|
| cp850		| 22	| Swedish OEM			|
| cp865		| 23	| Norwegian OEM			|
| cp437		| 24	| Spanish OEM			|
| cp437		| 25	| English OEM (Great Britain)	|
| cp850		| 26	| English OEM (Great Britain)	|
| cp437		| 27	| English OEM (US)		|
| cp863		| 28	| French OEM (Canada)		|
| cp850		| 29	| French OEM			|
| cp852		| 31	| Czech OEM			|
| cp852		| 34	| Hungarian OEM			|
| cp852		| 35	| Polish OEM			|
| cp860		| 36	| Portuguese OEM		|
| cp850		| 37	| Portuguese OEM		|
| cp866		| 38	| Cyrillic OEM			|
| cp850		| 55	| English OEM (US)		|
| cp852		| 64	| Romanian OEM			|
| cp936		| 77	| Chinese GBK (PRC)		|
| cp949		| 78	| Korean (ANSI/OEM)		|
| cp950		| 79	| Chinese Big5 (Taiwan)		|
| cp874		| 80	| Thai (ANSI/OEM)		|
| default	| 87	| Current ANSI CP ANSI		|
| cp1252	| 88	| Western European ANSI		|
| cp1252	| 89	| Spanish ANSI			|
| cp852		| 100	| Eastern European MS-DOS	|
| cp866		| 101	| Cyrillic MS-DOS		|
| cp865		| 102	| Nordic MS-DOS			|
| cp861		| 103	| Icelandic MS-DOS		|
| cp850		| 104	| Kamenicky (Czech) MS-DOS 895	|
| cp850		| 105	| Mazovia (Polish) MS-DOS 620	|
| cp737		| 106	| Greek MS-DOS (437G)		|
| cp857		| 107	| Turkish MS-DOS		|
| cp863		| 108	| French-Canadian MS-DOS	|
| cp950		| 120	| Taiwan Big 5			|
| cp949		| 121	| Hangul (Wansung)		|
| cp936		| 122	| PRC GBK			|
| cp932		| 123	| Japanese Shift-JIS		|
| cp874		| 124	| Thai Windows/MSDOS		|
| cp737		| 134	| Greek OEM			|
| cp852		| 135	| Slovenian OEM			|
| cp857		| 136	| Turkish OEM			|
| macCyrillic	| 150	| Cyrillic Macintosh		|
| macCentEuro	| 151	| Eastern European Macintosh	|
| macGreek	| 152	| Greek Macintosh		|
| cp1250	| 200	| Eastern European Windows	|
| cp1251	| 201	| Cyrillic Windows		|
| cp1254	| 202	| Turkish Windows		|
| cp1253	| 203	| Greek Windows			|
| cp1257	| 204	| Baltic Windows		|
