//################################################################################
//    Markdown_Init, svgml_process
//    create_append_paragraph
//    output_markdown, output_paragraph, parse_inlines
//    Svgml::process, parse_data, append_tspans
//################################################################################

#include <exception>
#include <stdio.h>
#include <stdlib.h>
#define _USE_MATH_DEFINES
#include <math.h>
  
#ifndef WIN32
  #include <sys/stat.h>
  #include <sys/types.h>
  #define mymkdir(A) mkdir(A,0777)
#else
  #include <direct.h>
  #define mymkdir _mkdir
  #define chdir _chdir
#endif
  
#include <glm/glm.hpp>
#include <glm/gtx/norm.hpp>
#include <glm/gtx/normal.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/transform.hpp>
#include <glm/gtc/quaternion.hpp>
#include <glm/gtx/quaternion.hpp>
#include <glm/gtx/vector_angle.hpp>
  
#define RADTODEG 180.0/M_PI
#define DEGTORAD M_PI/180.0
  
#include "markdown.h"
  
using namespace glm;

//################################################################################
//    exceptions
//################################################################################

typedef enum class EXP {
  undefined,needs_recalculate,try_again
} MarkdownExceptions;

class MarkdownException
{
  public:
  
  MarkdownException(MarkdownExceptions e) throw() { etype_=e; }
  MarkdownExceptions etype_;
};

#define UNUSED(expr) do { (void)(expr); } while (0)
  
//################################################################################
//    declarations
//################################################################################
  
static int manage_link_attributes(const char* buffer,MyTSchar* out,
  MyTSchar* id=NULL,MyTSchar* fileName=NULL,int* numbering=NULL,MyTSchar* display=NULL,
  MyTSchar* create=NULL,const char* add_class=NULL);
  
static const char* eval_tcl(Tcl_Interp* interp,const char* script);
static const char* eval_tcl(Tcl_Interp* interp,MyTScharList& cmdList);
//static const char* eval_tcl(MyTScharList& cmdList);

void sha1( unsigned char *input, int ilen, unsigned char output[20] );

Tcl_Interp* MKstate::ip_=NULL;
int MKstate::init_ggcLib_=0;

//################################################################################
//    file utilities & base64
//################################################################################
  
static void read_fileG(const char* fileName,MyTSchar& res,int as_binary=0)
{
  
  int len=strlen(fileName);
  MyTSchar fileNameE(len*3);
  Tcl_UtfToExternal(NULL,NULL,fileName,len,0,NULL,fileNameE.v(),
    fileNameE.num(),NULL,&len,NULL);
  fileNameE.print(len,"");
  
  const char* mode="r";
  if(as_binary) mode="rb";
  
  FILE* fin=fopen(fileNameE.v(),mode);
  if(!fin){
    throw MyTSchar("Error reading file '%s'",fileName);
  }
  int c=0; res.set_num(1000);
  while(1){
    size_t n=fread(&res[c],1,res.num()-c,fin);
    if(n==0) break;
    res.set_num(res.num()*2);
    c+=n;
  }
  res.print(c,"");
  fclose(fin);
}

static void write_fileG_if_different(const char* fileName,const char* res,int as_binary)
{
  int len=strlen(fileName);
  MyTSchar fileNameE(len*3);
  Tcl_UtfToExternal(NULL,NULL,fileName,len,0,NULL,fileNameE.v(),
    fileNameE.num(),NULL,&len,NULL);
  fileNameE.print(len,"");
  
  size_t res_len=strlen(res);
  
  const char* mode="r";
  if(as_binary) mode="rb";
  
  FILE* fin=fopen(fileNameE.v(),mode);
  if(fin){
    MyTSchar res_old;
    int c=0; res_old.set_num(1000);
    while(1){
      size_t n=fread(&res_old[c],1,res_old.num()-c,fin);
      if(n==0) break;
      res_old.set_num(res_old.num()*2);
      c+=n;
    }
    res_old.print(c,"");
    fclose(fin);
    if(res_len==res_old.num() && strcmp(res,res_old.v())==0){
      return;
    }
  } else {
    MyTSchar dir=fileName;
    file_dirname(dir);
    mymkdir(dir.v()); 
  }
  mode="w";
  if(as_binary) mode="wb";
  FILE* fout=fopen(fileNameE.v(),mode);
  if(!fout){
    throw MyTSchar("Error writing file '%s'",fileName);
  }
  size_t n=fwrite(res,1,res_len,fout);
  if(n!=res_len){
    throw MyTSchar("Error writing file '%s' n=%d",fileName,n);
  }
  fclose(fout);
}

void MKstate::check_init_ip()
{
  if(!ip_){
    ip_=Tcl_CreateInterp();
  }
}

void MKstate::check_init_ip_gid_group_conds()
{
  if(!ip_){
    ip_=Tcl_CreateInterp();
  }
  if(!init_ggcLib_){
    const char* script=""
      "set ::tcl_library C:/TclTk/ActiveTcl8.6-x64/lib/tcl8.6\n"
      "set ::env(TCL_LIBRARY) C:/TclTk/ActiveTcl8.6-x64/lib/tcl8.6\n"
      "source $::env(TCL_LIBRARY)/init.tcl\n"
      "lappend ::auto_path ~/myTclTk/gid_groups_conds_dir ~/myTclTk/compass"
      " ~/myTclTk/customLib_dir\n"
      "package require gid_groups_conds\n"
      "package require gid_groups_conds::ggcLib\n"
      "package require compass_utils\n"
      "mylog::init debug\n"
      "gid_groups_conds::start_problemtype compassfem\n";
    eval_tcl(ip_,script);
    init_ggcLib_=1;
  }
}

void MKstate::create_gid_file(const char* geoFile,const char* batch)
{
  MyTScharList cmdList;
  
  this->check_init_ip_gid_group_conds();
  
  MyTSchar dirname=geoFile;
  file_dirname(dirname);
  if(strcmp(file_extension(dirname.v()),".gid")!=0){
    throw MyTSchar("directory '%s' does not have gid extension");
  }
  MyTSchar dirnameB=dirname;
  dirnameB.printE("~");
  cmdList.setList("file","delete","-force",dirnameB.v(),NULL);
  eval_tcl(ip_,cmdList);
  cmdList.setList("file","rename",dirname.v(),dirnameB.v(),NULL);
  try { eval_tcl(ip_,cmdList); }
  catch(MyTSchar& c){ UNUSED(c); }
  mymkdir(dirname.v());
  MyTSchar batchfile=geoFile;
  file_root(batchfile);
  batchfile.printE(".bch");
  write_fileG_if_different(batchfile.v(),batch,0);
  
  cmdList.setList("draw_post::import_batch_file_do",batchfile.v(),NULL);
  eval_tcl(ip_,cmdList);
}

static int check_length_and_linesize(char *target,size_t* datalength,size_t* linelength,size_t targsize,size_t maxlinesize){
  if (*datalength == targsize) return -1;
  if(maxlinesize> 0 && *linelength==maxlinesize) {
    target[*datalength]='\n';
    (*datalength)++;
    if (*datalength == targsize) return -1;
    *linelength=0;
  }
  return 0;
}

static const char Base64[] =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char Pad64 = '=';

/* ramsan: added maxlinesize. If it is equal to zero, there is no maximum */
int b64_encode(char *src, size_t srclength, char *target, size_t targsize,size_t maxlinesize)
{
  size_t datalength = 0,linelength=0;
  unsigned char input[3];
  unsigned char output[4];
  size_t i;
  
  while (2 < srclength) {
    input[0] = *src++;
    input[1] = *src++;
    input[2] = *src++;
    srclength -= 3;
    
    output[0] = input[0] >> 2;
    output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
    output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);
    output[3] = input[2] & 0x3f;
    
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    target[datalength++] = Base64[output[0]]; linelength++;
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    target[datalength++] = Base64[output[1]]; linelength++;
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    target[datalength++] = Base64[output[2]]; linelength++;
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    target[datalength++] = Base64[output[3]]; linelength++;
  }
  
/* Now we worry about padding. */
  if (0 != srclength) {
/* Get what's left. */
    input[0] = input[1] = input[2] = '\0';
    for (i = 0; i < srclength; i++)
      input[i] = *src++;
    
    output[0] = input[0] >> 2;
    output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
    output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);
    
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    target[datalength++] = Base64[output[0]];  linelength++;
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    target[datalength++] = Base64[output[1]]; linelength++;
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    if (srclength == 1)
      target[datalength++] = Pad64;
    else
    target[datalength++] = Base64[output[2]];
    linelength++;
    if(check_length_and_linesize(target,&datalength,&linelength,targsize,maxlinesize)==-1) return -1;
    target[datalength++] = Pad64; linelength++;
  }
  if (datalength >= targsize)
    return (-1);
  target[datalength] = '\0';  /* Returned value doesn't count \0. */
  return ( int)(datalength);
}

static int is_little_endian()
{
  volatile uint32_t i=0x01234567;
  // return 0 for big endian, 1 for little endian.
  return (*((uint8_t*)(&i))) == 0x67;
}

static int32_t big_endian2little_endian(int32_t num)
{
  return ((num>>24)&0xff) | // move byte 3 to byte 0
  ((num<<8)&0xff0000) | // move byte 1 to byte 2
  ((num>>8)&0xff00) | // move byte 2 to byte 1
  ((num<<24)&0xff000000); // byte 0 to byte 3
}

void pngsize_data(MyTSchar& data,int& width,int& height)
{
  if(data.num()<33){
    throw MyTSchar("File not large enough to contain PNG header");
  }
  MyTSint bytes;
  bytes={-119,80,78,71,13,10,26,10};
  for(int i=0;i<8;i++){
    if(data[i]!=bytes[i]){
      throw MyTSchar("data is not a PNG file");
    }
  }
  bytes={0,0,0,13,73,72,68,82};
  for(int i=0;i<8;i++){
    if(data[i+8]!=bytes[i]){
      throw MyTSchar("data is missing a leading IHDR chunk");
    }
  }
  int32_t width32,height32;
  memcpy(&width32,&data[16],sizeof(width32));
  memcpy(&height32,&data[20],sizeof(width32));

  if(is_little_endian()){
    width32=big_endian2little_endian(width32);
    height32=big_endian2little_endian(height32);
  }
  width=width32;
  height=height32;
}

//################################################################################
//    string svg utilities
//################################################################################

typedef enum class ST {
  none,newline,tab,sub,sup,asterisk1,asterisk2,asterisk3,underline1,underline2,underline3
} SvgmlSplitText;

const char* const SvgmlSplitText_g_[]={"","\n","\t","~","^","*","**","***","_","__","___",NULL};

class SvgmlSplitTextC
{
  public:
  void set(SvgmlSplitText type,const char* text){
    types_.append(type); text_.setV(text); }
  
  int has_tab(){ for(int i=0;i<types_.num();i++){ if(types_[i]==ST::tab) return 1;} return 0; }
  int has_newline(){ for(int i=0;i<types_.num();i++){ if(types_[i]==ST::newline) return 1;} return 0; }
  
  MyTSvec<SvgmlSplitText,3> types_;
  MyTSchar text_;
};

inline int is_chars(int mychar,const char* chars)
{
  return strchr(chars,mychar)!=NULL;
}

static void split_text_set_unescaped_text(MyTSchar& out,const char* txt,int len)
{
  out.clear();
  for(int i=0;i<len;i++){
    if(txt[i]=='\r') continue;
    if(txt[i]=='\\' && i<len-1 && is_chars(txt[i+1],"\\*_^~")) continue;
    out.append(txt[i]);
  }
}

inline void split_text(MyTSchar& text,MyTSvec<SvgmlSplitTextC,3>& splits)
{
  const char* mA[1],*mAA[1]; int mL[1],mLL[1];
  if(text.regexp(0,"[\n\t]")){
    MyTScharList lines;
    string_split(text.v(),"\r?[\n\t]\r?",lines,1);
    for(int i=0;i<lines.num();i+=2){
      MyTSvec<SvgmlSplitTextC,3> splitsL;
      split_text(lines[i],splitsL);
      if(splitsL.num()==0){
        if(lines[i].num()==0) lines[i].print0(" ");
        splitsL.incr_num().set(ST::none,lines[i].v());
      }
      if(i>0 && splitsL.num()){
        if(lines[i-1].regexp(0,"\n")) splitsL[0].types_.append(ST::newline);
        else splitsL[0].types_.append(ST::tab);
      }
      for(int j=0;j<splitsL.num();j++){
        splits.append(splitsL[j]);
      }
    }
  } else {
    int c=0;
    while(string_regexp(text.v(),c,-1,"[~^*_]{1,3}",mA,mL,1)){
      c=mA[0]-text.v();
      if(c>0 && text[c-1]=='\\' && (c==1 || text[c-2]!='\\')){
        c+=mL[0];
        continue;
      }
      if(text[c]=='_' && c>0 && string_regexp(text.v(),c-1,-1,"\\w_{1,3}\\w")){
        c+=mL[0];
        continue;
      }
      MyTSchar rexTS("\\%c{%d}",mA[0][0],mL[0]);
      if(string_regexp(text.v(),mA[0]-text.v()+mL[0],-1,rexTS.v(),mAA,mLL,1)==0){
        c+=mL[0];
        continue;
      }
      MyTSchar textL;
      textL.setV(text.v(),mA[0]-text.v());
      split_text(textL,splits);
      
      MyTSchar sep;
      sep.setV(mA[0],mL[0]);
      int pos=string_isin_pos(sep.v(),SvgmlSplitText_g_);
      SvgmlSplitText type=SvgmlSplitText(pos);
      textL.setV(mA[0]+mL[0],mAA[0]-(mA[0]+mL[0]));
      MyTSvec<SvgmlSplitTextC,3> splitsL;
      split_text(textL,splitsL);
      for(int j=0;j<splitsL.num();j++){
        splitsL[j].types_.append(type);
        splits.append(splitsL[j]);
      }
      textL.setV(mAA[0]+mLL[0],text.num()-(mAA[0]-text.v()+mLL[0]));
      split_text(textL,splits);
      return;
    }
    if(text.num()){
      MyTSchar textL;
      split_text_set_unescaped_text(textL,text.v(),text.num());
      splits.incr_num().set(ST::none,textL.v());
    }
  }
}

//################################################################################
//    string utilities
//################################################################################

inline int is_same_char_line(MyTSchar& buffer,int start,int end,
  int allow_spaces,int min_chars)
{
  int num_chars=1;
  for(int i=start+1;i<=end;i++){
    if(is_chars(buffer[i]," \t")){
      if(allow_spaces==0) return 0;
    } else if(buffer[i]!=buffer[start]){
      return 0;
    } else {
      num_chars++; 
    }
  }
  if(num_chars>=min_chars) return 1;
  else return 0;
}

inline int num_same_char_line_prefix(MyTSchar& buffer,int start,int end,
  int allow_spaces)
{
  int num_chars=1;
  for(int i=start+1;i<=end;i++){
    if(is_chars(buffer[i],Unicode_space_g_)){
      if(allow_spaces==0) break;
    } else if(buffer[i]!=buffer[start]){
      break;
    } else {
      num_chars++; 
    }
  }
  return num_chars;
}

inline int link_label_name(MyTSchar& buffer,int startB,MyTSchar& name)
{
  int start=-1,end=-1;
  for(int i=startB;i<buffer.num();i++){
    if(is_chars(buffer[i]," \t\r\n")){
      // nothing
    } else if(is_chars(buffer[i],"\n")){
      if(start==-1) return 0;
    } else if(is_chars(buffer[i],"[")){
      if(start==-1) start=i+1;
      else return 0;
    } else if(is_chars(buffer[i],"]")){
      if(start==-1) return 0;
      end=i-1;
      break;
    } else if(is_chars(buffer[i],"\\")){
      if(start==-1) return 0;
      i++;
    } else {
      if(start==-1) return 0;
    }
  }
  if(start==-1 || end==-1) return 0;
  name.setV(&buffer[start],end-start+1);
  return end+2;
}

inline void link_normalize(MyTSchar& name)
{
  while(name.num() && is_chars(name[0],ASCII_space_g_)){
    name.clear(0);
  }
  while(name.num() && is_chars(name[end_MTS],ASCII_space_g_)){
    name.clear(end_MTS);
  }
  int space0=-1;
  for(int pos=0;pos<name.num();pos++){
    if(is_chars(name[pos],ASCII_space_g_)){
      if(space0==-1){
        name[pos]=' ';
        space0=pos;
      } else {
        name.clear(pos);
        pos--;
      }
    } else {
      space0=-1;
    }
  }
  Tcl_UtfToLower(name.v());
}

inline int link_text(MyTSchar& buffer,int startB,int end,MyTSchar& text)
{
  int start=-1,endL=-1,num_brackets=0;
  for(int i=startB;i<=end;i++){
    if(is_chars(buffer[i]," \t\r\n")){
      // nothing
    } else if(is_chars(buffer[i],"\n")){
      if(start==-1) return 0;
    } else if(is_chars(buffer[i],"[")){
      if(start==-1) start=i+1;
      else num_brackets++;
    } else if(is_chars(buffer[i],"]")){
      if(start==-1) return 0;
      else if(num_brackets){
        num_brackets--; 
      } else {
        endL=i-1;
        break;
      }
    } else if(is_chars(buffer[i],"\\")){
      if(start==-1) return 0;
      i++;
    } else {
      if(start==-1) return 0;
    }
  }
  if(start==-1 || endL==-1) return 0;
  if(num_brackets) return 0;
  text.setV(&buffer[start],endL-start+1);
  return endL+2;
}

inline int link_destination(MyTSchar& buffer,int startB,MyTSchar& url)
{
  int start=-1,end=-1,num_endlines=0,smaller_than=0,parentheses=0;
  
  for(int i=startB;i<buffer.num();i++){
    if(is_chars(buffer[i]," \t\r")){
      if(start!=-1 && smaller_than==0){
        if(parentheses) return 0;
        end=i-1;
        break;
      }
    } else if(is_chars(buffer[i],"\n")){
      if(start==-1){
        num_endlines++;
        if(num_endlines>1) return 0;
      } else if(smaller_than==0){
        if(parentheses) return 0; 
        end=i-1;
        break;
      } else {
        return 0;
      }
    } else if(is_chars(buffer[i],"<")){
      if(start==-1){
        start=i+1;
        smaller_than=1;
      } else if(smaller_than>0){
        return 0;
      }
    } else if(is_chars(buffer[i],">")){
      if(smaller_than>0){
        end=i-1;
        break;
      }
      if(start==-1) start=i;
    } else if(is_chars(buffer[i],"(") && smaller_than==0){
      parentheses++;
      if(start==-1) start=i;
    } else if(is_chars(buffer[i],")") && smaller_than==0){
      parentheses--;
      if(start==-1) start=i;
      if(parentheses<0){
        end=i-1;
        break;
      }
    } else if(is_chars(buffer[i],"\\")){
      if(start==-1) start=i;
      i++;
    } else {
      if(start==-1) start=i;
    }
  }
  if(start==-1) return 0;
  if(smaller_than && end==-1) return 0;
  if(end==-1) end=buffer.num()-1;
  
  url.setV(&buffer[start],end-start+1);
  
  if(smaller_than) return end+2;
  else return end+1;
}

inline int link_title(MyTSchar& buffer,int startB,MyTSchar& title)
{
  int start=-1,end=-1,num_spaces=0,num_non_spaces=0,num_endlines=0;
  char openC;
  
  for(int i=startB;i<buffer.num();i++){
    if(is_chars(buffer[i]," \t\r")){
      if(start==-1) num_spaces++;
    } else if(is_chars(buffer[i],"\n")){
      if(start==-1){
        num_spaces++;
        num_endlines++;
        if(num_endlines>1) return 0;
      } else {
        if(num_non_spaces==0) return 0;
        num_non_spaces=0;
      }
    } else if(is_chars(buffer[i],"\"'")){
      if(start==-1){
        if(num_spaces==0) return 0;
        openC=buffer[i];
        start=i+1;
        num_non_spaces++;
      } else if(buffer[i]==openC){
        end=i-1;
        break;
      } else {
        num_non_spaces++;
      }
    } else if(is_chars(buffer[i],"(")){
      if(start==-1){
        if(num_spaces==0) return 0;
        openC=buffer[i];
        start=i+1;
      } else if(openC=='('){
        return 0;
      } else {
        num_non_spaces++;
      }
    } else if(is_chars(buffer[i],")")){
      if(start==-1){
        return 0;
      } else if(openC=='('){
        end=i-1;
        break;
      } else {
        num_non_spaces++;
      }
    } else if(is_chars(buffer[i],"\\")){
      if(start==-1) return 0;
      num_non_spaces++;
      i++;
    } else {
      if(start==-1) return 0;
      num_non_spaces++;
    }
  }
  if(start==-1 || end==-1) return 0;
  
  title.setV(&buffer[start],end-start+1);
  title.regsub(0,"\\\\\"","\"");
  return end+2;
}

inline int spaces_num(MyTSchar& buffer,int start,int* num_spaces=NULL)
{
  if(num_spaces) (*num_spaces)=0;
  for(int i=start;i<buffer.num();i++){
    if(is_chars(buffer[i]," ")){
      if(num_spaces) (*num_spaces)++;
    } else if(is_chars(buffer[i],"\t")){
      if(num_spaces) (*num_spaces)+=4;
    } else if(is_chars(buffer[i],"\r\n")){
      return i;
    } else {
      return i;
    }
  }
  return buffer.num();
}

inline int incr_chars(MyTSchar& buffer,int start,int num,int* num_spaces=NULL,
  int* num_increased=NULL)
{
  if(num_spaces) (*num_spaces)=0;
  if(num_increased) (*num_increased)=0;
  if(num==0) return start;
  
  int num_chars=0;
  for(int i=start;i<buffer.num();i++){
    if(is_chars(buffer[i]," ")){
      if(num_spaces) (*num_spaces)++;
      num_chars++;
    } else if(is_chars(buffer[i],"\t")){
      if(num_chars+4>num){
        int len=0;
        for(int j=i-1;j>=0;j--){
          if(buffer[j]!='\n') len++;
          else break;
        }
        int delta=4-len%4;
        buffer.clear(i);
        buffer.insertV(i,"    ",delta);
        if(num_increased) (*num_increased)+=delta-1;
        if(num_spaces) (*num_spaces)++;
        num_chars++;
      } else {
        if(num_spaces) (*num_spaces)+=4;
        num_chars+=4;
      }
    } else if(is_chars(buffer[i],"\r\n")){
      if(num_spaces) (*num_spaces)++;
      num_chars++;
    } else {
      num_chars++;
    }
    if(num_chars>=num){
      return i+1;
    }
  }
  return buffer.num();
}

static int find_closing_delimiterExact(MyTSchar& buffer,int start,int end,char c,
  int num)
{
  for(int i=start;i<=end;i++){
    if(buffer[i]==c){
      int nReal=num_same_char_line_prefix(buffer,i,end,0);
      if(nReal!=num){
        i+=nReal;
        continue;
      }
      return i;
    }
  }
  return -1;
}

static int find_closing_delimiter(MyTSchar& buffer,int start,int end,char c,int num)
{
  for(int i=start;i<=end;i++){
    if(buffer[i]==c){
      int nMax=num_same_char_line_prefix(buffer,i,end,0);
      if(nMax<num) continue;
      return i;
    }
  }
  return -1;
}

// static int find_closing_delimiterEM(MyTSchar& buffer,int start,int end0,int end,char c,int num)
// {
//   for(int i=start;i<=end;i++){
//     if(buffer[i]==c){
//       int nMax=num_same_char_line_prefix(buffer,i,end,0);
//       if(nMax<num) continue;
//       if(is_chars(buffer[i-1],ASCII_space_g_)) continue;
//       if(buffer[i-1]!=c && is_chars(buffer[i-1],ASCII_punctuation_g_)){
//         if(i+num<=end && !is_chars(buffer[i+num],ASCII_punctuation_SP_g_)){
//           continue; 
//         }
//         if(i+num<=end0 && buffer[i+num]==c){
//           continue;
//         }
//       }
//       if(i>start && buffer[i-1]==buffer[i]){
//         //continue;
//       }
//       if(i+num<end0 && buffer[i+num]==buffer[i]){
//         continue;
//       }
//       if(i+num<=end && buffer[i]=='_' &&
//         !is_chars(buffer[i+num],Unicode_space_g_) &&
//         !is_chars(buffer[i+num],ASCII_punctuation_SP_g_)){
//         continue;
//       }
//       return i;
//     }
//   }
//   return -1;
// }

// static int is_raw_html(MyTSchar& buffer,int start,int end)
// {
//   const char* ma[6]; int mL[6];
//   
//   if(string_regexp(buffer.v(),start,end+1,"^</?[a-zA-Z][-\\w]*(?:[ \t]([^>]*)>|>)",ma,mL,1)){
//     return ma[0]+mL[0]-1-buffer.v();
//   } else if(string_regexp(buffer.v(),start,end+1,"^<!--.*?-->",ma,mL,1)){
//     return ma[0]+mL[0]-1-buffer.v();
//   } else if(string_regexp(buffer.v(),start,end+1,"^<\\?[^>]*\\?>",ma,mL,1)){
//     return ma[0]+mL[0]-1-buffer.v();
//   } else if(string_regexp(buffer.v(),start,end+1,"^<![^>]*>",ma,mL,1)){
//     return ma[0]+mL[0]-1-buffer.v();
//   } else if(string_regexp(buffer.v(),start,end+1,"^<!\\[CDATA\\[.*\\]\\]>",ma,mL,1)){
//     return ma[0]+mL[0]-1-buffer.v();
//   }
//   return -1;
// }

// static int is_autolink(MyTSchar& buffer,int start,int end)
// {
//   const char* ma[1]; int mL[1];
//   
//   const char* rex="^<\\w[-+.\\w]{1,31}:[^\\s<>]*>";
//   if(string_regexp(buffer.v(),start,end+1,rex,ma,mL,1)==0) return -1;
//   return ma[0]+mL[0]-1-buffer.v();
// }

inline void output_quoted_char(MyTSchar& out,char c)
{
  switch(c){
    case '<': out.printE("&lt;"); break;
    case '>': out.printE("&gt;"); break;
    case '&': out.printE("&amp;"); break;
    case '"': out.printE("&quot;"); break;
    default:  out.printE("%c",c); break;
  }
}

void MKstate::set_extensions(MyTScharList& extensions)
{
  for(int i=0;i<extensions.num()-1;i+=2){
    int ipos=string_isin_pos(extensions[i].v(),MarkdownExtensions_g_);
    if(ipos==-1){
      throw MyTSchar("unknown extension '%s'. Possible extensions: %s",
        extensions[i].v(),string_join(MarkdownExtensions_g_,","));
    }
    int value;
    if(strcmp(extensions[i+1].v(),"1")==0){
      value=1;
    } else if(strcmp(extensions[i+1].v(),"0")==0){
      value=0;
    } else {
      throw MyTSchar("unknown extension value '%s'. must be '0' or '1'",
        extensions[i+1].v());
    }
    active_extensions_.set(ggclong(ipos),value);
    if(ggclong(ipos)==ggclong(EXT::none)){
      active_extensions_.set(ggclong(EXT::all),(value)?0:1);
    } else if(ggclong(ipos)==ggclong(EXT::all)){
      active_extensions_.set(ggclong(EXT::none),(value)?0:1);
    }
  }
}

void MKstate::output_quoted_string_nobackslash(MyTSchar& buffer,MyTSchar& out,
  int start,int end)
{
  for(int i=start;i<=end;i++){
    int pos=this->entities_json_to_c(buffer,out,i);
    if(pos!=-1){
      i=pos;
      continue;
    }
    output_quoted_char(out,buffer[i]);
  }
}

void MKstate::output_quoted_string_code_span(MyTSchar& buffer,MyTSchar& out,
  int start,int end)
{
  for(int i=start;i<=end;i++){
    char c=buffer[i];
    if(c=='\n') c=' ';
    if((i==start || i==end) && is_chars(buffer[start]," \n") &&
      is_chars(buffer[end]," \n") &&
      string_regexp(buffer.v(),start,end+1,"^\\s+$")==0){
      continue; 
    }
    if(c=='\t'){
      output_quoted_char(out,'\\');
      output_quoted_char(out,'t');
    } else {
      output_quoted_char(out,c);
    }
  }
}

inline void output_quoted_string(MyTSchar& out,const char* c)
{
  while(*c!='\0'){
    if(*c=='\\' && is_chars(*(c+1),ASCII_punctuation_g_)){
      c++;
    }
    output_quoted_char(out,*c);
    c++;
  }
}

inline void output_quoted_stringB(MyTSchar& out,const char* c)
{
  while(*c!='\0'){
    output_quoted_char(out,*c);
    c++;
  }
}

inline void replace_backslash(MyTSchar& out)
{
  for(int i=0;i<out.num();i++){
    if(out[i]=='\\' && i<out.num()-1 && is_chars(out[i+1],ASCII_punctuation_g_)){
      out.clear(i);
      i--;
    }
  }
}

inline void output_url_encoded_stringDo(MyTSchar& buffer,MyTSchar& out,
  int start,int end)
{
//      case '%': output_quoted_string(out,"%25"); break;
  for(int i=start;i<=end;i++){
    switch(buffer[i]){
      case ' ': output_quoted_string(out,"%20"); break;
      case '[': output_quoted_string(out,"%5B"); break;
      case '\\': output_quoted_string(out,"%5C"); break;
      case ']': output_quoted_string(out,"%5D"); break;
      case '`': output_quoted_string(out,"%60"); break;
      case '"': output_quoted_string(out,"%22"); break;
      default:
      {
        if(buffer[i]<33){
          MyTSchar value("%%%02X",(unsigned char) buffer[i]);
          output_quoted_string(out,value.v()); break;
        } else {
          output_quoted_char(out,buffer[i]);
        }
      }
      break;
    }
  }
}

void MKstate::output_url_encoded_string(MyTSchar& buffer,MyTSchar& out,
  int start,int end)
{
  for(int i=start;i<=end;i++){
    MyTSchar outL;
    int pos=this->entities_json_to_c(buffer,outL,i);
    if(pos!=-1){
      output_url_encoded_stringDo(outL,out,0,outL.num()-1);
      i=pos;
      continue;
    }
    output_url_encoded_stringDo(buffer,out,i,i);
  }
}

int MKstate::entities_json_to_c(MyTSchar& buffer,MyTSchar& out,int start)
{
  Tcl_Obj* bufptr=NULL;
  
  if(!is_setup_entities_json_to_c_){
    this->setup_entities_json_to_c();
  }
  MyTSchar matches[3]; int match0;
  if(buffer.regexp(start,"^&#([xX]?)(\\w{1,7});",matches,3,0,match0)){
    if(matches[2].num()==0) return -1;
    if(matches[1].num()){
      matches[2].insertV(0,"0x",-1);
    }
    char* end;
    int ivalue=strtol(matches[2].v(),&end,0);
    if(*end!='\0') return -1;
    if(ivalue==0){
      // this is Unicode Character 'REPLACEMENT CHARACTER' (U+FFFD)
      out.printE("\xEF\xBF\xBD");
      return match0+matches[0].num()-1;
    }
    bufptr=Tcl_ObjPrintf("\\u%04x",ivalue);
  } else if(buffer.regexp(start,"^&[^\\s;]+;",matches,1,0,match0)){
    const char* value=entities_json_to_c_.get(matches[0].v());
    if(!value) return -1;
    bufptr=Tcl_NewStringObj(value,-1);
  } else {
    return -1;
  }
  Tcl_IncrRefCount(bufptr);
  this->check_init_ip();
  Tcl_Obj* resPtr=Tcl_SubstObj(ip_,bufptr,TCL_SUBST_BACKSLASHES);
  if(strcmp(Tcl_GetString(resPtr),"&")==0){
    out.printE("&amp;");
  } else if(strcmp(Tcl_GetString(resPtr),"\"")==0){
    out.printE("&quot;");
  } else if(strcmp(Tcl_GetString(resPtr),"<")==0){
    out.printE("&lt;");
  } else if(strcmp(Tcl_GetString(resPtr),">")==0){
    out.printE("&gt;");
  } else {
    out.printE("%s",Tcl_GetString(resPtr));
  }  
  
  Tcl_DecrRefCount(resPtr);  
  //Tcl_DecrRefCount(bufptr);
  return match0+matches[0].num()-1;
}

//################################################################################
//    measure text in svg
//################################################################################

#ifdef WIN32
#include <windows.h>
#include <atlstr.h>
  
///////////////////////////////////////////////////////////////////////////////
// GetFontFile
//
// Note:  This is *not* a foolproof method for finding the name of a font file.
//        If a font has been installed in a normal manner, and if it is in
//        the Windows "Font" directory, then this method will probably work.
//        It will probably work for most screen fonts and TrueType fonts.
//        However, this method might not work for fonts that are created 
//        or installed dynamically, or that are specific to a particular
//        device, or that are not installed into the font directory.

//////////////////////////////////////////////////////////////////////////////
// GetNextNameValue
LONG GetNextNameValue(HKEY key, LPCTSTR subkey, LPTSTR szName, LPTSTR szData)
{
  static HKEY hkey = NULL;
  static DWORD dwIndex = 0;
  LONG retval;
  
  if (subkey == NULL && szName == NULL && szData == NULL)
  {
    if (hkey)
      RegCloseKey(hkey);
    hkey = NULL;
    return ERROR_SUCCESS;
  }
  
  if (subkey && subkey[0] != 0)
  {
    retval=RegOpenKeyEx(key,subkey,0,KEY_QUERY_VALUE,&hkey);
    if (retval != ERROR_SUCCESS)
    {
      return retval;
    }
    else
    {
    }
    dwIndex = 0;
  }
  else
  {
    dwIndex++;
  }
  
  *szName = 0;
  *szData = 0;
  
  char szValueName[MAX_PATH];
  DWORD dwValueNameSize = sizeof(szValueName)-1;
  BYTE szValueData[MAX_PATH];
  DWORD dwValueDataSize = sizeof(szValueData)-1;
  DWORD dwType = 0;
  
  retval = RegEnumValue(hkey, dwIndex, szValueName, &dwValueNameSize, NULL, 
    &dwType, szValueData, &dwValueDataSize);
  if (retval == ERROR_SUCCESS) 
  {
    lstrcpy(szName, (char *)szValueName);
    lstrcpy(szData, (char *)szValueData);
  }
  else
  {
  }
  
  return retval;
}

// BOOL GetFontFile(LPCTSTR lpszFontName, CString& strDisplayName, CString& strFontFile)
// {
//   _TCHAR szName[2 * MAX_PATH];
//   _TCHAR szData[2 * MAX_PATH];
//   
//   CString strFont;
//   strFont = _T("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts");
//   
//   strFontFile.Empty();
//   
//   BOOL bResult = FALSE;
// 
//   while (GetNextNameValue(HKEY_LOCAL_MACHINE, strFont, szName, szData) == ERROR_SUCCESS)
//   {
//     if (_strnicmp(lpszFontName, szName, strlen(lpszFontName)) == 0)
//     {
//       strDisplayName = szName;
//       strFontFile = szData;
//       bResult = TRUE;
//       //break;
//     }
//     
//     strFont.Empty();        // this will get next value, same key
//   }
//   
//   GetNextNameValue(HKEY_LOCAL_MACHINE, NULL, NULL, NULL);        // close the registry key
// 
//   strFont=_T("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts");
//   while(GetNextNameValue(HKEY_CURRENT_USER,strFont,szName,szData) == ERROR_SUCCESS)
//   {
//     if(_strnicmp(lpszFontName,szName,strlen(lpszFontName)) == 0)
//     {
//       strDisplayName=szName;
//       strFontFile=szData;
//       bResult=TRUE;
//       //break;
//     }
// 
//     strFont.Empty();        // this will get next value, same key
//   }
// 
//   GetNextNameValue(HKEY_CURRENT_USER,NULL,NULL,NULL);        // close the registry key
//   
//   return bResult;
// }

void get_windows_fonts(MyTScharListH& fonts)
{
  _TCHAR szName[2 * MAX_PATH];
  _TCHAR szData[2 * MAX_PATH];
  
  DWORD dwType=0;
  BYTE szValueData[MAX_PATH];
  DWORD dwValueDataSize = sizeof(szValueData)-1;
  LONG retval;
  
  MyTSchar fontsdir;
  CString key=_T("Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders");
  retval=RegGetValueA(HKEY_CURRENT_USER,key,"Fonts",RRF_RT_ANY,&dwType,szValueData,&dwValueDataSize);
  if(retval==ERROR_SUCCESS){
    fontsdir.setV((char*) szValueData,-1);
  } else {
    key=_T("system\\currentControlSet\\Control\\Session Manager\\Environment");
    retval=RegGetValueA(HKEY_LOCAL_MACHINE,key,"windir",RRF_RT_ANY,&dwType,szValueData,&dwValueDataSize);
    if(retval==ERROR_SUCCESS){
      fontsdir.setV((char*) szValueData,-1);
      fontsdir.printE("\\fonts");
    } else {
      fontsdir.print0("C:\\WINDOWS\\fonts");
    }
  }
  
  CString strFont;
  strFont = _T("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts");
  while (GetNextNameValue(HKEY_LOCAL_MACHINE, strFont, szName, szData) == ERROR_SUCCESS){
    if(strchr(szData,'\\')==NULL){
      fonts.appendH(szName).print0("%s\\%s",fontsdir.v(),szData);
    } else {
      fonts.appendH(szName)=szData;
    }
    strFont.Empty();
  }
  GetNextNameValue(HKEY_LOCAL_MACHINE, NULL, NULL, NULL);

  strFont=_T("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts");
  while (GetNextNameValue(HKEY_CURRENT_USER, strFont, szName, szData) == ERROR_SUCCESS){
    fonts.appendH(szName)=szData;
    strFont.Empty();
  }
  GetNextNameValue(HKEY_CURRENT_USER, NULL, NULL, NULL);
}

#else

#include <fontconfig.h>
  
void get_linux_fonts(MyTSchar& pattern,MyTScharListH& fonts)
{
  FcConfig* config = FcInitLoadConfigAndFonts();
  
  FcPattern* pat = FcNameParse((const FcChar8*)(pattern.v()));
  FcConfigSubstitute(config, pat, FcMatchPattern);
  FcDefaultSubstitute(pat);
  FcPattern* font = FcFontMatch(config, pat, NULL);
  if (font)
  {
    FcChar8* file = NULL;
    if (FcPatternGetString(font, FC_FILE, 0, &file) == FcResultMatch)
    {
      fonts.appendH(pattern.v())=(char*)file;
    }
    FcPatternDestroy(font);
  }
}

#endif // WIN32

#include <ft2build.h>
#include FT_FREETYPE_H
  
class FT_FontMeasure
{
  public:
  
  FT_FontMeasure();
  ~FT_FontMeasure();
  void set_font_name(const char* fontname,FT_FontWeight fweight,FT_FontStyle fstyle);
  void give_char_bbox(int codepoint,double font_size,dvec4& bbox);
  void measure_text_line(const char* text,const char* fontname,FT_FontWeight fweight,
    FT_FontStyle fstyle,double font_size,dvec4& boxG);
  void measure_text(const char* text,const char* fontname,FT_FontWeight fweight,
    FT_FontStyle fstyle,double font_size,
    dvec4& boxG,dvec4& boxG_line1);
  
  private:
  FT_Library library_;
  MyTSvecH<FT_Face,3> faces_;
  int iface_;
};

FT_FontMeasure *font_measure_g_=NULL;

FT_FontMeasure::FT_FontMeasure()
{
  FT_Error error=FT_Init_FreeType(&library_);
  if(error!=0){
    throw MyTSchar("error initializing FT_Init_FreeType");
  }
  iface_=-1;
}

FT_FontMeasure::~FT_FontMeasure()
{
  for(int i=0;i<faces_.num();i++){
    FT_Done_Face(faces_[i]);
  }
  FT_Done_FreeType(library_);
}
  
void FT_FontMeasure::set_font_name(const char* fontname,FT_FontWeight fweight,FT_FontStyle fstyle)
{
  MyTSchar fontnameF("%s,%s,%s",fontname,FT_FontWeight_g_[int(fweight)],FT_FontStyle_g_[int(fstyle)]);
  if(faces_.exists(fontnameF.v())){
    iface_=faces_.Mytextlongtable::get(fontnameF.v());
    return;
  }
  MyTScharListH fonts;
  
#ifdef WIN32
  get_windows_fonts(fonts);
#else
  MyTSchar pattern;
  pattern.print0("\"%s",fontname);
  if(fweight==FW::bold) pattern.printE(":weight=%s",FT_FontWeight_g_[fweight]);
  if(fstyle!=FS::normal) pattern.printE(":slant=%s",FT_FontStyle_g_[fstyle]);
  get_linux_fonts(pattern,fonts);
#endif
  
  if(strcasecmp(fontname,"sans-serif")==0){
    fontname="Arial";
  } else if(strcasecmp(fontname,"serif")==0){
    fontname="Times New Roman";
  } else if(strcasecmp(fontname,"monospace")==0){
    fontname="Courier";
  }
  
  MyTSvec<IntDouble,10> sorted_fonts;
  int search_id=-1; const char* fontnameL; ggclong pos;
  while((pos=fonts.Mytextlongtable::nextv(search_id,fontnameL))!=-1){
    if(strncasecmp(fontname,fontnameL,strlen(fontname))==0){
      sorted_fonts.incr_num().set(pos,100.0);
    } else if(strncasecmp("Arial",fontnameL,strlen("Arial"))==0){
      sorted_fonts.incr_num().set(pos,1.0);
    } else {
      continue;
    }
    if(string_regexp(fontnameL,0,-1,"(?i)Regular")==1){
      if(fweight==FW::normal && fstyle==FS::normal) sorted_fonts[end_MTS].v_+=10;
      else sorted_fonts[end_MTS].v_-=10;
    }
    if(string_regexp(fontnameL,0,-1,"(?i)Bold")==1){
      if(fweight==FW::bold) sorted_fonts[end_MTS].v_+=5;
      else sorted_fonts[end_MTS].v_-=5;
    }
    if(string_regexp(fontnameL,0,-1,"(?i)Italic")==1){
      if(fstyle==FS::italic) sorted_fonts[end_MTS].v_+=5;
      else if(fstyle==FS::oblique) sorted_fonts[end_MTS].v_+=2;
      else sorted_fonts[end_MTS].v_-=5;
    }
    if(string_regexp(fontnameL,0,-1,"(?i)Oblique")==1){
      if(fstyle==FS::oblique) sorted_fonts[end_MTS].v_+=5;
      else if(fstyle==FS::italic) sorted_fonts[end_MTS].v_+=2;
      else sorted_fonts[end_MTS].v_-=5;
    }
    if(string_regexp(fontnameL,0,-1,"(?i)Semi")==1){
      sorted_fonts[end_MTS].v_-=1;
    }
  }
  sorted_fonts.sort();
  
  faces_.appendH(fontnameF.v());
  iface_=faces_.num()-1;
  
  int is_good=1;
  for(int i=sorted_fonts.num()-1;i>=0;i--){
    int pos=sorted_fonts[i].iv_;
    FT_Error error=FT_New_Face(library_,fonts[pos].v(),0,&faces_[iface_]);
    if(!error){
      is_good=1;
      if(faces_[iface_]->style_flags&FT_STYLE_FLAG_ITALIC){
        if(fstyle==FS::normal) is_good=0;
      } else {
        if(fstyle!=FS::normal) is_good=0;
      }
      if(faces_[iface_]->style_flags&FT_STYLE_FLAG_BOLD){
        if(fweight==FW::normal) is_good=0;
      } else {
        if(fweight!=FW::normal) is_good=0;
      }
      if(!is_good){
        FT_Done_Face(faces_[iface_]);
      } else {
        break;
      }
    } else {
      is_good=0; 
    }
  }
  if(!is_good){
    for(int i=sorted_fonts.num()-1;i>=0;i--){
      int pos=sorted_fonts[i].iv_;
      FT_Error error=FT_New_Face(library_,fonts[pos].v(),0,&faces_[iface_]);
      if(!error){
        is_good=1;
        break;
      } else {
        is_good=0; 
      }
    }
  }
  if(!is_good){
    faces_.remove(fontnameF.v());
    faces_.decr_num();
    throw MyTSchar("error loading font '%s'",fontname);
  }
}

void FT_FontMeasure::give_char_bbox(int codepoint,double font_size,dvec4& box)
{
  FT_UInt glyph_index=FT_Get_Char_Index(faces_[iface_],codepoint);
  //if(glyph_index==0) return 1;
  FT_Error error=FT_Load_Glyph(faces_[iface_],glyph_index,FT_LOAD_NO_SCALE);
  //if(error) return error;
  if(error) return;
  FT_Glyph_Metrics gm=faces_[iface_]->glyph->metrics;

  box[0]=0;
  box[1]=(gm.horiBearingY-gm.height)*font_size/faces_[iface_]->units_per_EM;
  box[2]=gm.horiAdvance*font_size/faces_[iface_]->units_per_EM;
  box[3]=gm.height*font_size/faces_[iface_]->units_per_EM;
}

void FT_FontMeasure::measure_text_line(const char* text,const char* fontname,FT_FontWeight fweight,
  FT_FontStyle fstyle,double font_size,dvec4& boxG)
{
  Tcl_UniChar ch;
  
  this->set_font_name(fontname,fweight,fstyle);

  boxG=dvec4();
  
  dvec4 boxL; int num;
  for(int i=0;text[i];i+=num){
    num=Tcl_UtfToUniChar(&text[i],&ch);
    this->give_char_bbox(ch,font_size,boxL);
    if(boxL[1]<boxG[1]){
      boxG[1]=boxL[1];
    }
    if((boxL[3]+boxL[1])>boxG[1]+boxG[3]){
      boxG[3]=boxL[3]+boxL[1]-boxG[1];
    }
    boxG[2]+=boxL[2];
  }
}

void FT_FontMeasure::measure_text(const char* text,const char* fontname,FT_FontWeight fweight,
  FT_FontStyle fstyle,double font_size,dvec4& boxG,dvec4& boxG_line1)
{
  int num;
  Tcl_UniChar ch;
  
  this->set_font_name(fontname,fweight,fstyle);

  boxG=dvec4();
  
  dvec4 boxG_line,boxL;
  MyTScharList lines;
  string_split_text_sep(text,-1,"\n",lines);
  for(int iline=0;iline<lines.num();iline++){
    boxG_line=dvec4();
    for(int i=0;i<lines[iline].num();i+=num){
      num=Tcl_UtfToUniChar(&text[i],&ch);
      this->give_char_bbox(ch,font_size,boxL);
      if(boxL[1]<boxG_line[1]){
        boxG_line[1]=boxL[1];
      }
      if((boxL[3]+boxL[1])>boxG_line[1]+boxG_line[3]){
        boxG_line[3]=boxL[3]+boxL[1]-boxG_line[1];
      }
      boxG_line[2]+=boxL[2];
    }
    if(boxG_line[2]>boxG[2]){
      boxG[2]=boxG_line[2];
    }
    if(iline<lines.num()-1 && 1.2*font_size>boxG_line[3]){
      boxG[3]+=1.2*font_size;
    } else {
      boxG[3]+=boxG_line[3];
    }
    if(lines.num()==1){
      boxG[1]=boxG_line[1];
    }
    if(iline==0) boxG_line1=boxG_line;
  }
}

// #include "font_to_svg.h"
//   
// std::stringstream font2svg::debug;
// MyTSvecH<font2svg::glyph,10> font_metrics_g_;
// 
// static void measure_text(const char* text,const char* font,double font_size,
//   dvec4& boxG,dvec4& boxG_line1)
// {
//   int num,is_init;
//   Tcl_UniChar ch;
//   
//   if(!font_metrics_g_.exists(font)){
//     font_metrics_g_.appendH(font);
//     is_init=0;
//   } else {
//     is_init=1;
//   }
//   font2svg::glyph& g=font_metrics_g_.getF_H(font);
//   
//   if(!is_init){
//     MyTSchar font_file("%s",font);
//     
// #ifdef WIN32
//       CString strDisplayName, strFontFile;
//     GetFontFile(font,strDisplayName,strFontFile);
//     if(strcmp(strFontFile,"")!=0){
//       font_file.print0("c:/Windows/fonts/%s",strFontFile);
//     }
// #endif
//     
//     try { g.init(font_file.v(),text); }
//     catch(const char* errstring){
//       errstring=NULL;
//       g.init("c:/Windows/fonts/arial.ttf",text);
//     }
//   }
//   boxG=boxG_line1=dvec4();
//   
//   dvec4 box,boxL;
//   vec4 boxL_F;
//   MyTScharList lines;
//   string_split_text_sep(text,-1,"\n",lines);
//   for(int iline=0;iline<lines.num();iline++){
//     box=dvec4();
//     for(int i=0;i<lines[iline].num();i+=num){
//       num=Tcl_UtfToUniChar((char*) &lines[iline][i],&ch);
//       g.init(ch);
// //     if(error){
// //       Tcl_SetObjResult(pI,Tcl_NewStringObj("error in measure_text",-1));
// //       return TCL_ERROR;
// //     }
//       g.give_metrics(&boxL_F[0]);
//       for(int j=0;j<4;j++) boxL[j]=boxL_F[j]/2048.0;
//       if(boxL[1]*font_size<box[1]){
//         box[1]=boxL[1]*font_size;
//       }
//       if((boxL[3]-boxL[1])*font_size>box[3]){
//         box[3]=(boxL[3]-boxL[1])*font_size;
//       }
//       box[2]+=boxL[2]*font_size;
//     }
//     if(box[2]>boxG[2]){
//       boxG[2]=box[2];
//     }
//     if(iline<lines.num()-1 && 1.2*font_size>box[3]){
//       boxG[3]+=1.2*font_size;
//     } else {
//       boxG[3]+=box[3];
//     }
//     if(lines.num()==1){
//       boxG[1]=box[1];
//     }
//     if(iline==0) boxG_line1=boxG;
//   }
// }

static int measure_text(ClientData clientData, Tcl_Interp *ip, int objc,Tcl_Obj *CONST objv[])
{
  double font_size;
  dvec4 boxG,boxG_line1;
  
  char err_args[]= "text font font-size";
  if (objc != 4) {
    Tcl_WrongNumArgs(ip,1,objv,err_args);
    return TCL_ERROR;
  }
  const char* text=Tcl_GetString(objv[1]);
  const char* font=Tcl_GetString(objv[2]);
  Tcl_GetDoubleFromObj(ip,objv[3],&font_size);
  
  font_measure_g_->measure_text(text,font,FW::normal,FS::normal,font_size,boxG,boxG_line1);
    
  Tcl_Obj* bufptr=Tcl_ObjPrintf("%g %g %g %g",boxG[0],boxG[1],boxG[2],boxG[3]);
  Tcl_SetObjResult(ip,bufptr);
  return TCL_OK;
}

//################################################################################
//    MKblocks
//################################################################################

void MKblocks::nprint(int iblock,MyTSvec<MKblocks,100>& blocks,
  MyTSchar& buffer,MyTSchar& deb)
{
  MyTSchar tmp;
  deb.printE("<block n='%d' p='%d' type='%s' blanks='%d %d' level='%d' "
    "tight='%d'>\n",iblock,parent_,MarkdownStates_g_[int(mtype_)],blanks_[0],
    blanks_[1],level_,tight_);
  
  if(posNoBlank_[0]>pos_[0]){
    tmp.setV(&buffer[pos_[0]],posNoBlank_[0]-pos_[0]);
    string_quote_xml(tmp);
    tmp.regsub(0,"\\n","\\\\n");
  } else {
    tmp.clear();
  }
  deb.printE("<t0>%s</t0>\n",tmp.v());
  
  if(posNoBlank_[0]>=0 && posNoBlank_[1]>=posNoBlank_[0]){
    tmp.setV(&buffer[posNoBlank_[0]],posNoBlank_[1]-posNoBlank_[0]+1);
    string_quote_xml(tmp);
    tmp.regsub(0,"\\n","\\\\n");
  } else {
    tmp.clear();
  }
  deb.printE("<t>%s</t>\n",tmp.v());
  
  if(posNoBlank_[1]<buffer.num()-1){
    tmp.setV(&buffer[posNoBlank_[1]+1],pos_[1]-posNoBlank_[1]);
    string_quote_xml(tmp);
    tmp.regsub(0,"\\n","\\\\n");
  } else {
    tmp.clear();
  }
  deb.printE("<t1>%s</t1>\n",tmp.v());
  
  deb.printE("<pos>%d,%d</pos> <posN>%d,%d</posN>\n",pos_[0],pos_[1],
    posNoBlank_[0],posNoBlank_[1]);
  
  for(int i=0;i<children_.num();i++){
    blocks[children_[i]].nprint(children_[i],blocks,buffer,deb);
  }
  deb.printE("</block>\n");
}

void MKblocks::print_yaml(int iblock,MyTSvec<MKblocks,100>& blocks,
  MyTSchar& buffer,MyTSchar& deb)
{
  MyTSchar indent;
  
  int parent=iblock;
  while(parent!=0){
    indent.printE("  ");
    parent=blocks[parent].parent_;
  }
  deb.printE("%s- {n: %d, p: %d, type: %s blanks: %d %d, level: %d tight: %d}\n",
    indent.v(),iblock,parent_,MarkdownStates_g_[int(mtype_)],blanks_[0],
    blanks_[1],level_,tight_);
  
  MyTSchar tmp;
  if(posNoBlank_[0]>pos_[0]){
    tmp.setV(&buffer[pos_[0]],posNoBlank_[0]-pos_[0]);
    //string_quote_xml(tmp);
    tmp.regsub(0,"\\n","\\\\n");
  } else {
    tmp.clear();
  }
  deb.printE("%s  - t0  : %s\n",indent.v(),tmp.v());
  
  if(posNoBlank_[0]>=0 && posNoBlank_[1]>=posNoBlank_[0]){
    tmp.setV(&buffer[posNoBlank_[0]],posNoBlank_[1]-posNoBlank_[0]+1);
    //string_quote_xml(tmp);
    tmp.regsub(0,"\\n","\\\\n");
  } else {
    tmp.clear();
  }
  deb.printE("%s  - t   : %s\n",indent.v(),tmp.v());
  
  if(posNoBlank_[1]<buffer.num()-1){
    tmp.setV(&buffer[posNoBlank_[1]+1],pos_[1]-posNoBlank_[1]);
    //string_quote_xml(tmp);
    tmp.regsub(0,"\\n","\\\\n");
  } else {
    tmp.clear();
  }
  deb.printE("%s  - t1  : %s\n",indent.v(),tmp.v());
  deb.printE("%s  - pos : %d,%d\n",indent.v(),pos_[0],pos_[1]);
  deb.printE("%s  - posN: %d,%d\n",indent.v(),posNoBlank_[0],posNoBlank_[1]);
  
  for(int i=0;i<children_.num();i++){
    blocks[children_[i]].print_yaml(children_[i],blocks,buffer,deb);
  }
}

//################################################################################
//    MKstate
//################################################################################

int MKstate::list_item_level_prefix(MyTSchar& buffer,int ibox)
{
  MyTSchar matches[1];
  
  int num_prefix=0;
  while(ibox!=0){
    if(blocks_[ibox].mtype_==MK::list_item){
      MKblocks& block=blocks_[ibox];
      buffer.regexp(block.pos_[0],"^\\s*([-+*]|\\d{1,9}[.\\)])\\s*",matches,1);
      num_prefix+=matches[0].num();
    }
    ibox=blocks_[ibox].parent_;
  }
  return num_prefix;
}

int MKstate::is_extension_active(MarkdownExtensions ext)
{
  if(active_extensions_.exists(ggclong(ext)) && 
    active_extensions_.get(ggclong(ext))==0) return 0;
  if(active_extensions_.get(ggclong(EXT::all))) return 1;
  if(active_extensions_.exists(ggclong(ext))) return 1;
  return 0;
}

int MKstate::give_prev(int iblock)
{
  MKblocks& block=blocks_[blocks_[iblock].parent_];
  int ipos=block.children_.isin_pos(iblock);
  if(ipos>0) return block.children_[ipos-1];
  return -1;
}

int MKstate::give_next(int iblock)
{
  MKblocks& block=blocks_[blocks_[iblock].parent_];
  int ipos=block.children_.isin_pos(iblock);
  if(ipos<block.children_.num()-1) return block.children_[ipos+1];
  return -1;
}

void MKstate::create_append_paragraph(MyTSchar& buffer,int current_level)
{
  int num_spaces,is_lazy_continuation=0;
  
  if(this->give_type(current_level)==MK::block_quote){
    is_lazy_continuation=1;
  }
  
//################################################################################
//    setext_heading
//################################################################################
  
  if(this->give_type(current_level)==MK::paragraph &&
    blanks_line_[0]<=3 && !is_lazy_continuation &&
    is_chars(buffer[SE_lineNoBlank_[0]],"-=")){
    int valid=is_same_char_line(buffer,SE_lineNoBlank_[0],SE_lineNoBlank_[1],0,1);
    if(valid){
      MKblocks& block=blocks_[open_blocks_[end_MTS]];
      block.mtype_=MK::setext_heading;
      if(buffer[SE_lineNoBlank_[0]]=='=') block.level_=1;
      else block.level_=2;
      this->curr_close();
      return;
    }
  }
  
//################################################################################
//    list_item
//################################################################################
  
  int is_list_item=0,is_list_item_cont=0; MyTSchar matches[2];
  int SE_lineL=SE_line_[0];
  
  if(this->give_type(current_level)==MK::list_item){
    int num_prefix=0,num_increased;
    MKblocks& block=blocks_[open_blocks_[current_level]];
    if(buffer.regexp(block.pos_[0],"^[ \t]*([-+*]|\\d{1,9}[.\\)])[ \t]*\n")){
      num_prefix=2;
    } else if(block.children_.num()){
      int pos=blocks_[block.children_[0]].posNoBlank_[0];
      if(blocks_[block.children_[0]].mtype_==MK::indented_code_block) pos-=4;
      else if(blocks_[block.children_[0]].mtype_==MK::fenced_code_block)
        pos=blocks_[block.children_[0]].pos_[0];
      num_prefix=pos-block.pos_[0];
    } else {
      num_prefix=2;
    }    
    if(blanks_line_[0]>=num_prefix){
      is_list_item_cont=1;
      SE_lineL=incr_chars(buffer,SE_line_[0],num_prefix,&blanks_line_[0],
        &num_increased);
      if(num_increased){
        SE_lineNoBlank_[0]+=num_increased;
        SE_line_[1]+=num_increased;
        SE_lineNoBlank_[1]+=num_increased;
        pos_+=num_increased;
      }
    }
  }
  
//################################################################################
//    block_quote
//################################################################################
  
  if(blanks_line_[0]<=3 && is_chars(buffer[SE_lineNoBlank_[0]],">") &&
    !is_list_item_cont){
    if(this->give_type(current_level)==MK::fenced_code_block){
      goto no_block_quote;
    }
    if(this->give_type(current_level)!=MK::block_quote){
      while(open_blocks_.num()>current_level) this->curr_close();
      this->append_block(MK::block_quote,SE_line_,SE_lineNoBlank_,
        blanks_line_);
    }
    SE_line_[0]=SE_lineNoBlank_[0]+1;
    
    if(is_chars(buffer[SE_line_[0]]," \t")){
      int num_increased;
      SE_line_[0]=incr_chars(buffer,SE_line_[0],1,&blanks_line_[0],&num_increased);
      if(num_increased){
        SE_lineNoBlank_[0]+=num_increased;
        SE_line_[1]+=num_increased;
        SE_lineNoBlank_[1]+=num_increased;
        pos_+=num_increased;
      }
    }
    SE_lineNoBlank_[0]=spaces_num(buffer,SE_line_[0],&blanks_line_[0]);
    this->create_append_paragraph(buffer,current_level+1);
    return;
  }
  
  no_block_quote:;
  
//################################################################################
//    thematic_break
//################################################################################
  
  if(blanks_line_[0]<=3 && is_chars(buffer[SE_lineNoBlank_[0]],"-_*") &&
    !is_list_item_cont){
    int valid=is_same_char_line(buffer,SE_lineNoBlank_[0],SE_lineNoBlank_[1],1,3);
    if(valid){
      if(is_lazy_continuation){
        this->close_all();
      } else {
        while(is_open(current_level)) this->curr_close();
      }
      this->append_block(MK::thematic_break,SE_line_,
        SE_lineNoBlank_,blanks_line_);
      this->curr_close();
      return;
    }
  }
  
//################################################################################
//    list_item cont
//################################################################################
  
  if(!is_list_item_cont && blanks_line_[0]<=3){
    if(is_chars(buffer[SE_lineNoBlank_[0]],"-+*")){
      is_list_item=1;
      SE_lineL=SE_lineNoBlank_[0]+1;
    } else if(buffer.regexp(SE_lineNoBlank_[0],"^(\\d{1,9})[.\\)]",matches,2)){
      if(this->give_type(current_level)!=MK::paragraph || strcmp(matches[1].v(),"1")==0){
        is_list_item=1;
        SE_lineL=SE_lineNoBlank_[0]+matches[0].num();
      }
    }
    if(is_list_item && is_chars(buffer[SE_lineL]," \t")){
      int num_increased;
      SE_lineL=incr_chars(buffer,SE_lineL,1,&blanks_line_[0],&num_increased);
      if(num_increased){
        SE_lineNoBlank_[0]+=num_increased;
        SE_line_[1]+=num_increased;
        SE_lineNoBlank_[1]+=num_increased;
        pos_+=num_increased;
      }
    } else if(buffer[SE_lineL]!='\n'){
      is_list_item=0;
    }
  }
  if(is_list_item || is_list_item_cont){
    if(this->give_type(current_level)==MK::fenced_code_block){
      goto no_list_item;
    }
    if(this->give_type(current_level)==MK::paragraph &&
      buffer.regexp(SE_lineNoBlank_[0],"^[ \t]*([-+*]|\\d{1,9}[.\\)])[ \t]*\n")){
      goto no_list_item;
    }
    if(this->give_type(current_level)!=MK::list_item || !is_list_item_cont){
      while(open_blocks_.num()>current_level) this->curr_close();
      if(!is_list_item_cont && this->give_type(current_level)==MK::list_item){
        this->curr_close();
      }
      this->append_block(MK::list_item,SE_line_,SE_lineNoBlank_,
        blanks_line_);
    }
    SE_line_[0]=SE_lineL;
    SE_lineNoBlank_[0]=spaces_num(buffer,SE_line_[0],&blanks_line_[0]);
    this->create_append_paragraph(buffer,current_level+1);
    return;
  }

  if(this->give_type(current_level)==MK::list_item){
    is_lazy_continuation=1;
  }
  no_list_item:;
  
//################################################################################
//    fenced_code_block
//################################################################################
  
  if(this->give_type(current_level)==MK::fenced_code_block){
    MKblocks& block=blocks_[open_blocks_[end_MTS]];
    int is_end=0;
    if(blanks_line_[0]<=3 && is_chars(buffer[SE_lineNoBlank_[0]],"`~")){
      is_end=is_same_char_line(buffer,SE_lineNoBlank_[0],
        SE_lineNoBlank_[1],0,block.level_);
      int pos=spaces_num(buffer,block.pos_[0]);
      if(buffer[SE_lineNoBlank_[0]]!=buffer[pos]) is_end=0;
    }
    if(SE_lineNoBlank_[0]==buffer.num()-1) is_end=1;
    if(is_end){
      block.pos_[1]=SE_line_[1];
      block.posNoBlank_[1]=SE_line_[0]-1;
      block.blanks_[1]=blanks_line_[1];
      this->curr_close();
      return;
    }
    if(0&& SE_line_[0]>block.pos_[1]+1){
      this->curr_close();
      SE_lineNoBlank_[1]=SE_line_[1];
      MKblocks& blockN=this->append_block(MK::fenced_code_block,SE_line_,
        SE_lineNoBlank_,blanks_line_);
      blockN.level_=block.level_;
      return;
    }
    block.pos_[1]=SE_line_[1];
    block.posNoBlank_[1]=SE_lineNoBlank_[1];
    block.blanks_[1]=blanks_line_[1];
    return;
  }
  
  if(blanks_line_[0]<=3 && is_chars(buffer[SE_lineNoBlank_[0]],"`~") &&
    this->give_type(current_level)!=MK::HTML_block){
    int level=num_same_char_line_prefix(buffer,SE_lineNoBlank_[0],SE_lineNoBlank_[1],0);
    int pos=-1;
    if(buffer[SE_lineNoBlank_[0]]=='`'){
      pos=find_closing_delimiter(buffer,SE_lineNoBlank_[0]+level,
        SE_lineNoBlank_[1],'`',1);
    }
    if(level>=3 && pos==-1){
      if(is_lazy_continuation){
        while(open_blocks_.num()>current_level){
          this->curr_close();
        }
      } else if(is_open(current_level)){
        this->curr_close();
      }
      SE_lineNoBlank_[0]=SE_line_[1]+1;
      MKblocks& block=this->append_block(MK::fenced_code_block,SE_line_,
        SE_lineNoBlank_,blanks_line_);
      block.level_=level;
      return;
    }
  }
  
//################################################################################
//    indented_code_block
//################################################################################
  
  if(this->give_type_last()==MK::indented_code_block){
    this->curr_close();
  }
  if(this->give_type_last()==MK::list_item && is_lazy_continuation &&
    blanks_line_[0]>=4){
    this->curr_close();
  }
  if(this->give_type_last()==MK::block_quote && is_lazy_continuation &&
    blanks_line_[0]>=4){
    this->curr_close();
  }
  if(!is_open(current_level) &&  blanks_line_[0]>=4){
    if(is_lazy_continuation){
      this->close_all();
    }
    int num_increased;
    SE_lineNoBlank_[0]=incr_chars(buffer,SE_line_[0],4,&blanks_line_[0],&num_increased);
    if(num_increased){
      SE_line_[1]+=num_increased;
      SE_lineNoBlank_[1]+=num_increased;
      pos_+=num_increased;
    }
    if(buffer[SE_lineNoBlank_[0]]!='\n'){
      this->append_block(MK::indented_code_block,SE_line_,SE_lineNoBlank_,
        blanks_line_);
      return;
    }
  }
  
//################################################################################
//    ATX_heading
//################################################################################
  
  if(blanks_line_[0]<=3 && is_chars(buffer[SE_lineNoBlank_[0]],"#")){
    IntVector2D level,start_end,blank;
    level[0]=1; start_end[0]=start_end[1]=-1;
    for(int i=SE_lineNoBlank_[0]+1;i<=SE_lineNoBlank_[1];i++){
      if(is_chars(buffer[i],"#") && start_end[0]==-1 && blank[0]==0){
        level[0]++;
      } else if(is_chars(buffer[i],"#") && blank[1]>0){
        level[1]++;
      } else if(is_chars(buffer[i]," \t")){
        if(start_end[0]==-1){
          blank[0]++;
          blank[1]++;
        } else {
          blank[1]++;
        }
      } else {
        if(start_end[0]==-1) start_end[0]=i;
        start_end[1]=i;
        blank[1]=0;
        level[1]=0;
      }
    }
    if(level[0]<=6 && (blank[0]>=1 || start_end[0]==-1)){
      if(is_lazy_continuation){
        this->close_all();
      } else if(is_open(current_level)) this->curr_close();
      MKblocks& block=this->append_block(MK::ATX_heading,SE_line_,start_end,
        blanks_line_);
      block.level_=level[0];
      this->curr_close();
      return;
    }
  }
  
//################################################################################
//    HTML_block
//################################################################################
  
  if(blanks_line_[0]<=3 && is_chars(buffer[SE_lineNoBlank_[0]],"<") &&
    this->give_type(current_level)!=MK::HTML_block){
    const char* rexsStart[]={
      "(?in)\\A<(script|pre|style)(\\s|>|$)",
        "(?in)\\A<!--",
        "(?in)\\A<\\?",
        "(?in)\\A<![A-Z]",
        "(?in)\\A<!\\[CDATA\\[",
        "(?in)\\A</?(address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|"
        "dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|"
        "h1|h2|h3|h4|h5|h6|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|nav|"
        "noframes|ol|optgroup|option|p|param|section|source|summary|table|tbody|td|tfoot|th|"
        "thead|title|tr|track|ul)(\\s|/?>|$)",
        "(?in)(\\A<[a-zA-Z][-\\w]*(\\s+[a-zA-Z_:][-\\w:.]*(\\s*=\\s*(([^\\s\"'=<>`]+)|('[^'\n]*')|(\"[^\"\n]*\")))*)*\\s*>\\s*\n)|"
        "(\\A</[a-zA-Z][-\\w]*\\s*>\\s*\n)"
      };
    int level=0;
    for(int i=0;i<7;i++){
      if(buffer.regexp(SE_lineNoBlank_[0],rexsStart[i])){
        level=i+1;
        break;
      }
    }
    if((level>0 && level<7) || (level==7 && is_open(current_level)==0)){
      if(is_lazy_continuation){
        this->close_all();
      } else if(is_open(current_level)) this->curr_close();
      SE_lineNoBlank_[0]=SE_line_[0];
      MKblocks& block=this->append_block(MK::HTML_block,SE_line_,
        SE_lineNoBlank_,blanks_line_);
      block.level_=level;
    }
  }
  
  if(this->give_type_last()==MK::HTML_block){
    const char* rexsEnd[]={
      "(?in)\\A[^\n]*</(script|pre|style)>",
        "(?in)\\A.*-->",
        "(?in)\\A.*\\?>",
        "(?in)\\A.*>",
        "(?in)\\A.*\\]\\]>",
        "(?in)\\A\\s*$",
        "(?in)\\A\\s*$"
      };
    MKblocks& block=blocks_[open_blocks_[end_MTS]];
    block.pos_[1]=SE_line_[1];
    block.posNoBlank_[1]=SE_lineNoBlank_[1];
    block.blanks_[1]=blanks_line_[1];    
    if(buffer.regexp(SE_lineNoBlank_[0],rexsEnd[block.level_-1])){
      int c=block.posNoBlank_[1];
      if(c>block.posNoBlank_[0] && is_chars(buffer[c],ASCII_space_g_)){
        c--;
      }
      block.posNoBlank_[1]=c;
      if(block.level_==1 && buffer[block.pos_[1]]=='\n'){
        block.posNoBlank_[1]=block.pos_[1];
      }
      this->curr_close();
    }
    return;
  }
  
//################################################################################
//    link_reference_definition
//################################################################################
  
  if(!is_open(current_level) && blanks_line_[0]<=3  &&
    is_chars(buffer[SE_lineNoBlank_[0]],"[")){
    MKlink& link=links_.incr_num();
    int c=link_label_name(buffer,SE_lineNoBlank_[0],link.name_);
    int c_noblank;
    if(c){
      link_normalize(link.name_);
      if(link.name_.num()==0) c=0;
      else if(buffer[c]!=':') c=0;
      else c++;
    }
    if(c){
      c=link_destination(buffer,c,link.url_);
    }
    if(c){
      int c_alt=link_title(buffer,c,link.title_);
      if(c_alt!=0){
        int c_alt2=spaces_num(buffer,c_alt,&num_spaces);
        if(c_alt2!=0 && is_chars(buffer[c_alt2],"\r\n")){
          c_noblank=c_alt;
          c=c_alt2;
        } else {
          c_alt=0;
        }
      }
      if(c_alt==0){
        c_noblank=c;
        c=spaces_num(buffer,c,&num_spaces);
        if(!is_chars(buffer[c],"\r\n")){
          c=0;
        }
      }
    }
    if(c){
      if(links_.exists(link.name_.v())){
        // necessary to emit a warning
      } else {
        links_.set(link.name_.v(),links_.num()-1);
      }
      SE_lineNoBlank_[1]=c_noblank;
      const char* mA[1]; int mL[1];
      const char* rex="\\A[ \t]*\n?[ \t]*\\{[^\n}]*\\}";
      if(string_regexp(buffer.v(),c,-1,rex,mA,mL,1)){
        c+=mL[0];
      }
      SE_line_[1]=c;
      blanks_line_[1]=c-c_noblank;
      this->append_block(MK::link_reference_definition,SE_line_,
        SE_lineNoBlank_,blanks_line_);
      link.ibox_=blocks_.num()-1;
      pos_=SE_line_[1];
      this->curr_close();
      return;
    } else {
      links_.decr_num();
    }
  }
  
//################################################################################
//    normal paragraph
//################################################################################
  
  int para_is_void=0;
  if(SE_lineNoBlank_[0]==-1) para_is_void=1;
  else if(SE_lineNoBlank_[0]>=SE_lineNoBlank_[1] && 
    is_chars(buffer[SE_lineNoBlank_[0]],ASCII_space_g_)) para_is_void=1;
  else if(SE_lineNoBlank_[0]==buffer.num()-1) para_is_void=1;
  
  if(!para_is_void && is_open(current_level) && 
    this->is_extension_active(EXT::tex_math_dollars) &&
    strncmp(&buffer[SE_lineNoBlank_[0]],"$$",2)==0){
    this->curr_close();
  }
  
  if(para_is_void){
    if(SE_lineNoBlank_[0]<buffer.num()-1){
      for(int i=open_blocks_.num();i>=current_level;i--){
        int iblock;
        if(i==open_blocks_.num()){
          if(blocks_[open_blocks_[end_MTS]].children_.num()){
            iblock=blocks_[open_blocks_[end_MTS]].children_[end_MTS];
          } else {
            continue;
          }
        } else {
          iblock=open_blocks_[i];
        }
        if(i<open_blocks_.num() && blocks_[iblock].mtype_==MK::fenced_code_block) break;
        blocks_[iblock].tight_=0;
        break;
      }
    }
    if(this->give_type_last()==MK::paragraph){
      this->curr_close();
    }
    if(this->give_type_last()==MK::list_item){
      int pos=blocks_[open_blocks_[end_MTS]].pos_[0];
      const char* rex="^[ \t]*([-+*]|\\d{1,9}[.\\)])[ \t]*\n";
      const char* mA[1]; int mL[1];
      if(string_regexp(buffer.v(),pos,-1,rex,mA,mL,1)==1 && pos+mL[0]<=SE_line_[0]){
        this->curr_close();
      }
    }
    if(is_lazy_continuation && this->give_type(current_level)==MK::block_quote){
      this->curr_close();
      if(this->num_open()>current_level){
        this->curr_close();
      }
    }
  } else if(is_open(current_level) && this->give_type(current_level)!=MK::document){
    MKblocks& block=blocks_[open_blocks_[end_MTS]];
    if(block.mtype_!=MK::paragraph){
      if(block.mtype_!=MK::list_item || current_level<open_blocks_.num()){
        this->curr_close();
        if(is_lazy_continuation){
          while(open_blocks_.num()>current_level){
            this->curr_close();
          }
        }
      }
      this->append_block(MK::paragraph,SE_line_,SE_lineNoBlank_,
        blanks_line_);
    } else {
      block.pos_[1]=SE_line_[1];
      block.posNoBlank_[1]=SE_lineNoBlank_[1];
      block.blanks_[1]=blanks_line_[1];
    }
  } else {
    if(is_lazy_continuation){
      this->close_all();
    }
    this->append_block(MK::paragraph,SE_line_,SE_lineNoBlank_,
      blanks_line_);
  }
}

void MKstate::process_markdown(MyTSchar& buffer)
{
  buffer_=&buffer;
  this->append_block(MK::document);
  
  MyTSchar buffer0=buffer; buffer.clear();
  for(int i=0;i<buffer0.num();i++){
    if(i<buffer0.num()-1 && buffer0[i]=='\\'){
//      if(buffer0[i+1]=='n'){
//        buffer.append('\n');
//      } else 
      if(buffer0[i+1]=='t'){
        buffer.append('\t');
//      } 
//      else if(buffer0[i+1]=='r'){
        // nothing
      } else {
        buffer.append(buffer0[i]);
        buffer.append(buffer0[i+1]);
      }
      i++;
    } else if(buffer0[i]=='\r'){
      // nothing
    } else {
      buffer.append(buffer0[i]);
    }
  }
  for(int i=0;i<buffer.num();i++){
    switch(buffer[i]){
      case ' ':
      {
        if(SE_line_[0]==-1){
          SE_line_[0]=i;
        }
        if(SE_lineNoBlank_[0]==-1){
          blanks_line_[0]++;
        } else {
          blanks_line_[1]++;
        }
      }
      break;
      case '\t':
      {
        if(SE_line_[0]==-1){
          SE_line_[0]=i;
        }
        if(SE_lineNoBlank_[0]==-1){
          blanks_line_[0]+=4;
        } else {
          blanks_line_[1]+=4;
        }
      }
      break;
      case '\n':  case '\r':
      {
        if(SE_line_[0]==-1){
          SE_line_[0]=i;
        }
        if(SE_lineNoBlank_[0]==-1){
          SE_lineNoBlank_[0]=i;
        }
        if(SE_lineNoBlank_[1]==-1){
          SE_lineNoBlank_[1]=i;
        }
        SE_line_[1]=i;
        
        pos_=i;
        this->create_append_paragraph(buffer,1);
        i=pos_;
        
        SE_line_[0]=SE_line_[1]=-1;
        SE_lineNoBlank_[0]=SE_lineNoBlank_[1]=-1;
        blanks_line_[0]=0;
        
        if(i<buffer.num()-1 && buffer[i]=='\r' && buffer[i+1]=='\n'){
          i++;
        }
      }
      break;
      case '\\':
      {
        if(SE_line_[0]==-1){
          SE_line_[0]=i;
        }
        if(SE_lineNoBlank_[0]==-1){
          SE_lineNoBlank_[0]=i;
        }
        SE_lineNoBlank_[1]=i;
        blanks_line_[1]=0;
      }
      break;  
      default:
      {
        if(SE_line_[0]==-1){
          SE_line_[0]=i;
        }
        if(SE_lineNoBlank_[0]==-1){
          SE_lineNoBlank_[0]=i;
        }
        SE_lineNoBlank_[1]=i;
        blanks_line_[1]=0;
      }
      break;
    }
  }
  
  if(this->is_extension_active(EXT::metadata_block)){
    for(int i=1;i<blocks_.num();i++){
      if(blocks_[i-1].mtype_!=MK::thematic_break) continue;
      if(blocks_[i].mtype_!=MK::setext_heading) continue;
      blocks_[i-1].mtype_=MK::none;
      blocks_[i].mtype_=MK::metadata_block;
      MyTScharList list;
      string_split_text_sep(&buffer[blocks_[i].posNoBlank_[0]],
        blocks_[i].posNoBlank_[1]-blocks_[i].posNoBlank_[0]+1,"\n",list);
      MyTSchar mA[3];
      for(int j=0;j<list.num();j++){
        if(list[j].regexp(0,"^\\s*(\\S+):\\s+(\\S.*\\S|\\S)\\s*$",mA,3)==1){
          metadata_.appendH(mA[1].v())=mA[2];
          if(strcmp(mA[1].v(),"extensions")==0){
            MyTScharList extensions;
            string_split_tcl_list(mA[2].v(),extensions);
            this->set_extensions(extensions);
          }
        }
      }
    }
  }
  if(this->is_extension_active(EXT::implicit_figures)){
    for(int i=0;i<blocks_.num();i++){
      if(blocks_[i].mtype_!=MK::paragraph) continue;
      int start=blocks_[i].posNoBlank_[0];
      int end=blocks_[i].posNoBlank_[1];
      const char* rex="!\\[[^\\]]*\\][([][^)]*[\\])]\\s*(\\{[^{}]*\\}\\s*)?$";
      if(!string_regexp(buffer.v(),start,end+1,rex)) continue;
      blocks_[i].mtype_=MK::implicit_figures;
    }
  }
  if(this->is_extension_active(EXT::pipe_tables)){
    const char* mA[3]; int mL[3];
    for(int i=0;i<blocks_.num();i++){
      if(blocks_[i].mtype_!=MK::paragraph) continue;
      int start=blocks_[i].posNoBlank_[0];
      int end=blocks_[i].posNoBlank_[1];
      const char* rex="(\\A\\||[^\\\\]\\|)[^\n]*\n[-\\s|:]*\\|[-\\s|:]*(\\Z|\n)";
      if(!string_regexp(buffer.v(),start,end+1,rex,mA,mL,3)) continue;
      if(i<blocks_.num()-1){
        int startN=blocks_[i+1].posNoBlank_[0];
        int endN=blocks_[i+1].posNoBlank_[1];
        if(string_regexp(buffer.v(),startN,endN+1,"\\A\\s*(Table)?:")){
          blocks_[i].posNoBlank_[1]=blocks_[i+1].posNoBlank_[1];
          blocks_[i].pos_[1]=blocks_[i+1].pos_[1];
          blocks_[i+1].mtype_=MK::none;
        }
      }
      blocks_[i].mtype_=MK::pipe_table;
    }
  }
  if(this->is_extension_active(EXT::definition_lists)){
    const char* mA[3]; int mL[3];
    for(int i=0;i<blocks_.num();i++){
      if(blocks_[i].mtype_!=MK::paragraph) continue;
      int start=blocks_[i].posNoBlank_[0];
      int end=blocks_[i].posNoBlank_[1];
      const char* rex="(^\\s{0,3}:)|(^[^\n]+\n\\s{0,3}:)";
      if(!string_regexp(buffer.v(),start,end+1,rex,mA,mL,3)) continue;
      if(mL[1]>0){
        if(i==0) continue;
        if(blocks_[i-1].mtype_!=MK::paragraph) continue;
        int startP=blocks_[i-1].posNoBlank_[0];
        int endP=blocks_[i-1].posNoBlank_[1];
        if(string_regexp(buffer.v(),startP,endP+1,"\n")) continue;
        blocks_[i].pos_[0]=blocks_[i-1].pos_[0];
        blocks_[i].posNoBlank_[0]=blocks_[i-1].posNoBlank_[0];
        blocks_[i-1].mtype_=MK::none;
      }
      blocks_[i].mtype_=MK::definition_lists;
    }
  }
  if(this->is_extension_active(EXT::link_attributes)){
    for(int i=0;i<blocks_.num();i++){
      int start,end,numbering=-1,has_att=0;
      MyTSchar id;
      if(blocks_[i].mtype_==MK::none) continue;
      if(blocks_[i].mtype_==MK::link_reference_definition) continue;
      if(blocks_[i].mtype_==MK::fenced_code_block){
        start=spaces_num(buffer,blocks_[i].pos_[0]);
        start+=num_same_char_line_prefix(buffer,start,blocks_[i].pos_[1],0);
        end=blocks_[i].posNoBlank_[0]-1;
      } else {
        start=blocks_[i].posNoBlank_[0];
        end=blocks_[i].pos_[1]-1;
        const char* mA[2]; int mL[2];
        if(string_regexp(buffer.v(),start,end+1,"\\{([^}]*)\\}\\s*\\Z",mA,mL,2)){
          start=mA[0]-buffer.v();
          blocks_[i].posNoBlank_[1]=start-1;
        } else {
          int found=0;
          if(string_regexp(buffer.v(),start,end+1,"\\A\\s*!\\[.*\\]\\[(.*)\\]\\s*\\Z",mA,mL,2)){
            MyTSchar name;
            name.setV(mA[1],mL[1]);
            MKlink* link=links_.getH(name.v());
            if(link){
              int iboxREF=link->ibox_;
              start=blocks_[iboxREF].posNoBlank_[0];
              end=blocks_[iboxREF].pos_[1]-1;
              if(string_regexp(buffer.v(),start,end+1,"\\{([^}]*)\\}\\s*\\Z",mA,mL,2)){
                start=mA[0]-buffer.v();
                found=1;
              }
            }
          }
          if(!found) start=-1;
        }
      }
      if(start!=-1){
        has_att=manage_link_attributes(&buffer[start],NULL,&id,NULL,&numbering);
      }
      if(is_heading(blocks_[i].mtype_)){
        blocks_[i].number_=++heading_numbersS_;
        if(id.num()==0){
          id.print0("heading %d",heading_numbersS_);
        }
        has_att=1;
      }
      if(!has_att) continue;
      if(id.num()==0) continue;
      
      MKid& mkid=idsG_.appendH(id.v());
      mkid.ibox_=i;
      
      if(numbering!=0 && this->is_extension_active(EXT::numbering)){
        switch(blocks_[i].mtype_){
          case MK::ATX_heading: case MK::setext_heading:
          {
            if(heading_numbers_.num()==0) heading_numbers_.set_num(6);
            for(int j=1;j<blocks_[i].level_;j++){
              if(heading_numbers_[j-1]==0) continue;
              if(mkid.number_.num()>0) mkid.number_.printE(".");
              mkid.number_.printE("%d",heading_numbers_[j-1]);
            }
            if(mkid.number_.num()>0) mkid.number_.printE(".");
            mkid.number_.printE("%d",++heading_numbers_[blocks_[i].level_-1]);
            for(int j=blocks_[i].level_+1;j<=6;j++){
              heading_numbers_[j-1]=0;
            }
          }
          break;
          case MK::implicit_figures:
          {
            if(numbering!=0){
              mkid.number_.print0("%d",++image_numbers_);
            }
          }
          break;
          case MK::pipe_table:
          {
            if(numbering!=0){
              mkid.number_.print0("%d",++table_numbers_);
            }
          }
          break;
          case MK::paragraph:
          {
            const char* mA[2]; int mL[2];
            int start=blocks_[i].posNoBlank_[0];
            int end=blocks_[i].posNoBlank_[1];
            if(string_regexp(buffer.v(),start,end+1,"\\A\\s*[$]{1,2}.*[$]{1,2}\\s*\\Z")){
              if(numbering!=0){
                mkid.number_.print0("%d",++formula_numbers_);
              }
            } else if(string_regexp(buffer.v(),start,end+1,"\\A\\s*\\[(\\d+)\\]",mA,mL,2)){
              int reference=atoi(mA[1]);
              if(reference && numbering!=0){
                mkid.number_.print0("%d",reference);
              }
            }
          }
          break;        
        }
      }
    }
  }
}

int MKstate::remove_block_quote_list_item_prefix(MyTSchar& buffer,int i,int end,int ibox)
{
  int level=this->block_quote_level(ibox);
  while(i<=end && level>0){
    if(buffer[i]=='>'){
      if(i<end && is_chars(buffer[i+1]," ")) i++;
      level--;
      if(level==0){
        i++;
        break;
      }
    } else {
      break;
    }
    i++;
  }
  int prefix=this->list_item_level_prefix(buffer,ibox);
  if(prefix>0){
    int num_spaces;
    spaces_num(buffer,i,&num_spaces);
    if(prefix>num_spaces) prefix=num_spaces;
    i+=num_spaces;
  }
  return i;
}

void MKstate::output_image(int iblock,MyTSchar& buffer,MyTSchar& out,MyTSchar& url,
  MyTSchar& title,MyTSchar& text,int ibox)
{
  MyTSchar id;
  
  MarkdownStates mtype=(ibox!=-1)?blocks_[ibox].mtype_:MK::none;
  
  if(mtype==MK::implicit_figures){
    out.printE("<figure>\n");
  }
  out.printE("<img src=\"");
  this->output_url_encoded_string(url,out,0,url.num()-1);
  out.printE("\"");
  
  int numbering=-1;
  if(mtype!=MK::pipe_table && this->is_extension_active(EXT::link_attributes)){
    manage_link_attributes(&buffer[blocks_[iblock].posNoBlank_[1]+1],&out,&id,NULL,&numbering);
  }
  
  if(1||text.num()){
    out.printE(" alt=\"");
    text.regsub(0,"/\\w+","");
    text.regsub(0,"[^\\w]"," ");
    text.regsub(0,"^\\s+|\\s+$","");
    text.regsub(0,"\\s+"," ");
    this->output_quoted_string_nobackslash(text,out,0,text.num()-1);
    out.printE("\"");
  }
  if(title.num()){
    out.printE(" title=\"");
    this->output_quoted_string_nobackslash(title,out,0,title.num()-1);
    out.printE("\"");
  }
  out.printE(" />");
  if(mtype==MK::implicit_figures){
    out.printE("<figcaption>");

    if(id.num() && numbering==1){
      static const char* imageName=NULL;
      if(!imageName){
        MyTSchar* lang=metadata_.getH("lang");
        const char* imageN[]={"en","Image","es","Imagen","ca","Imatge",NULL};
        MyhashvecC<char> imageNC(imageN);
        if(lang){
          imageName=imageNC.get(lang->v());
        }
        if(!imageName){
          imageName=imageNC.get("en");
        }
      }
      MKid* mkid=idsG_.getH(id.v());
      if(mkid && mkid->number_.num()){
        out.printE("<strong>%s %s</strong>. ",imageName,mkid->number_.v());
      }
    }
    this->output_paragraph(text,out,0,text.num()-1,-1);
    out.printE("</figcaption>\n");
    out.printE("</figure>\n");
  }
}

void MKstate::output_link(MyTSchar& out,MyTSchar& url,MyTSchar& title,
  MyTSchar& text,int ibox,int parse_text)
{
  out.printE("<a href=\"");
  this->output_url_encoded_string(url,out,0,url.num()-1);
  out.printE("\"");
  if(title.num()){
    out.printE(" title=\"");
    this->output_quoted_string_nobackslash(title,out,0,title.num()-1);
    out.printE("\"");
  }
  out.printE(">");
  if(parse_text){
    this->output_paragraph(text,out,0,text.num()-1,ibox,
      int(OPO::no_backslash_escapes));
  } else {
    output_quoted_stringB(out,text.v());
  }
  out.printE("</a>");
}

inline int num_chars(MyTSchar& buffer,int pos,int end)
{
  for(int i=pos+1;i<=end;i++){
    if(buffer[i]!=buffer[pos]) return i-pos;
  }
  return end-pos+1;
}

inline int has_code_end(MyTSchar& buffer,int start,int end,
  MyTSvec<MKinline,20>& inlines,MyTSint6& code_active)
{
  for(int i=start;i<=end;i++){
    if(buffer[i]=='`'){
      int len=num_chars(buffer,i,end);
      for(int j=code_active.num()-1;j>=0;j--){
        int pos=code_active[j];
        if(len==inlines[pos].len_) return 1;
      }
    }
  }
  return 0;
}

inline int check_set_code(MyTSchar& buffer,ivec2 start,int end,
  MyTSvec<MKinline,20>& inlines,MyTSint6& code_active)
{
  for(int i=start[0];i<=start[1];i++){
    if(buffer[i]=='`'){
      int len=num_chars(buffer,i,end);
      if(i==start[0] || buffer[i-1]!='`'){
        int found=0;
        for(int j=code_active.num()-1;j>=0;j--){
          int pos=code_active[j];
          if(len==inlines[pos].len_){
            inlines[pos].end_=i;
            inlines.incr_num().set(MK::code_span,i,inlines[pos].start_,len);
            inlines[pos].i_alt_=inlines.num()-1;
            inlines[end_MTS].i_alt_=pos;
            code_active.clear(j);
            found=1;
            i+=len-1;
            break;
          }
        }
        if(found){
          if(i>=start[1]) return len;
          continue;
        }
      }
      if(i==start[0] || buffer[i-1]!='\\'){
        inlines.incr_num().set(MK::code_span,i,len);
        code_active.append(inlines.num()-1);
        i+=len-1;
        if(i>=start[1]) return len;
        continue;
      }
    }
  }
  return 0;
}

// return -1 if not
inline int is_autolink(MyTSchar& buffer,int i,int end,MyTSvec<MKinline,20>& inlines,
  MyTSint6& code_active)
{
  const char* rex="\\A<("
    "([a-zA-Z][-+.\\w]{1,31}:[^\\s<>]*)|"
    "([a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    "(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)"
    ")>";
  const char* mA[1]; int mL[1];
  if(string_regexp(buffer.v(),i,end+1,rex,mA,mL,1)==1){
    int has_code=has_code_end(buffer,i,i+mL[0]-1,inlines,code_active);
    if(!has_code) return i+mL[0]-1;
  }
  return -1;
}

// return -1 if not
inline int is_html(MyTSchar& buffer,int i,int end,MyTSvec<MKinline,20>& inlines,
  MyTSint6& code_active)
{
  const char* rexH="\\A<("
    "([a-zA-Z][-\\w]*(\\s+[a-zA-Z_:][-\\w:.]*(\\s*=\\s*([^\\s\"'=<>`]+|'[^']*'|\"[^\"]*\"))*)*\\s*/?)|"
    "(/[a-zA-Z][-\\w]*\\s*)|"
    "(!--[^>]*--)|"
    "(\\?[^>]*\\?)|"
    "(![^>]*)|"
    "(!\\[CDATA\\[.*\\]\\])"
    ")>";
  const char* mA[1]; int mL[1];
  if(string_regexp(buffer.v(),i,end+1,rexH,mA,mL,1)==1){
    if(string_regexp(buffer.v(),i,end+1,"\\A<!--")==1 &&
      string_regexp(buffer.v(),i+3,end-7,"(^-?>)|(-$)|(--)")==1) return -1;
    int has_code=has_code_end(buffer,i,i+mL[0]-1,inlines,code_active);
    if(!has_code) return i+mL[0]-1;
  }
  return -1;
}

int MKstate::is_link_name(MyTSchar& buffer,int j,int end,int is_image,
  MyTSvec<MKinline,20>& inlines,MyTSint6& code_active)
{
  int num_open=1;
  for(;j<=end;j++){
    if(buffer[j]=='\\') j++;
    else if(buffer[j]=='['){
    if(!is_image && buffer[j-1]!='!' && this->is_link_or_image(buffer,j,end,
      inlines,code_active,1)!=-1) return -1;
      num_open++;
    } else if(buffer[j]==']'){
      num_open--;
      if(num_open==0) break;
    } else if(buffer[j]=='<'){
      if(is_autolink(buffer,j,end,inlines,code_active)!=-1) return -1;
      if(is_html(buffer,j,end,inlines,code_active)!=-1) return -1;
    }
  }
  if(num_open!=0) return -1;
  return j;
}

int MKstate::is_link_href(MyTSchar& buffer,int j,int end)
{
  while(j<end && is_chars(buffer[j],Unicode_space_g_)) j++;
  if(buffer[j]=='<'){
    for(j++;j<=end;j++){
      if(buffer[j]=='\\') j++;
      else if(buffer[j]=='\n' || buffer[j]=='>') break;
    }
    if(buffer[j]!='>') return -1;
    j++;
    if(j>end) return -1;
    if(!is_chars(buffer[j],Unicode_space_g_) && buffer[j]!=')') return -1;
  } else if(!is_chars(buffer[j],"\"'()")){
    int num_open=0;
    for(;j<=end;j++){
      if(buffer[j]=='\\') j++;
      else if(buffer[j]=='(') num_open++;
      else if(buffer[j]==')'){
        if(num_open==0) break;
        num_open--;
      } else if(is_chars(buffer[j],Unicode_space_g_)) break;
    }
    if(num_open!=0) return -1;
    if(j>end) return -1;
    if(!is_chars(buffer[j],Unicode_space_g_) && buffer[j]!=')') return -1;
  }
  while(j<end && is_chars(buffer[j],Unicode_space_g_)) j++;
  if(is_chars(buffer[j],"\"'(")){
    int j0=j;
    for(j++;j<=end;j++){
      if(buffer[j]=='\\') j++;
      else if(buffer[j0]=='"' && buffer[j]=='"') break;
      else if(buffer[j0]=='\'' && buffer[j]=='\'') break;
      else if(buffer[j0]=='(' && is_chars(buffer[j],"()")) break;
    }
    if(!is_chars(buffer[j],"\"')")) return -1;
    j++;
  }
  while(j<end && is_chars(buffer[j],Unicode_space_g_)) j++;
  if(buffer[j]!=')') return -1;
  return j;
}

// return -1 if not
int MKstate::is_link_or_image(MyTSchar& buffer,int i,int end,MyTSvec<MKinline,20>& inlines,
  MyTSint6& code_active,int only_basic_link)
{
  int j,is_link=0,is_reference=0,num_open;
  MyTSchar text,name;
  
  if(buffer[i]=='!'){
    if(i==end || buffer[i+1]!='[') return -1;
    j=i+2;
  } else {
    j=i+1;
  }
  int ret=this->is_link_name(buffer,j,end,buffer[i]=='!',inlines,code_active);
  if(ret==-1) return -1;
  text.setV(&buffer[j],ret-j);
  j=ret+1;
  if(j<=end && buffer[j]=='('){
    int ret=this->is_link_href(buffer,j+1,end);
    if(ret!=-1){
      is_link=1;
      j=ret;
    }
  } else if(j<=end && buffer[j]=='['){
    //if(only_basic_link) return -1;
    num_open=1;
    int j0=j+1;
    for(j++;j<=end;j++){
      if(buffer[j]=='\\') j++;
      else if(buffer[j]=='['){
        num_open++;
        break;
      } else if(buffer[j]==']'){
        num_open--;
        if(num_open==0) break;
      }
    }
    if(num_open!=0) return -1;
    name.setV(&buffer[j0],j-j0);
    is_reference=1;
  }
  
  if(!is_link && !is_reference){
    if(only_basic_link) return -1;
    name=text;
    j--;
  }
  
  if(name.num()!=0){
    link_normalize(name);
    MKlink* link=links_.getH(name.v());
    if(!link) return -1;
  }  
  return j;
}
    
void MKstate::parse_inlines(MyTSchar& buffer,int start,int end,
  MyTSvec<MKinline,20>& inlines,int output_paraOpts)
{
  inlines.clear();
  
  int num_emphasis=0;
  MyTSint6 code_active;
  for(int i=start;i<=end;i++){
    switch(buffer[i]){
      case '\\':
      {
        if(output_paraOpts&int(OPO::no_backslash_escapes)) break;
        if(i<end && buffer[i+1]=='`' && code_active.num()){
          // nothing
        } else if(i<end && is_chars(buffer[i+1],ASCII_punctuation_g_)){
          i++;
        }
      }
      break;
      case '`':
      {
        int len=check_set_code(buffer,ivec2(i,i),end,inlines,code_active);
        i+=len-1;
      }
      break;
      case '*': case '_':
      {
        int len=num_chars(buffer,i,end);
                
        ivec2 is_space,is_punctuation,is_delimiter,can_open_close;
        if(i==start || is_chars(buffer[i-1],Unicode_space_g_)) is_space[0]=1;
        if(i+len>end || is_chars(buffer[i+len],Unicode_space_g_)) is_space[1]=1;
        if(i>start && is_chars(buffer[i-1],ASCII_punctuation_g_)) is_punctuation[0]=1;
        if(i+len<=end && is_chars(buffer[i+len],ASCII_punctuation_g_)) is_punctuation[1]=1;
        
        if(!is_space[1] && (is_punctuation[1]==0 || (is_punctuation[1]==1 && (is_punctuation[0] ||
          is_space[0])))) is_delimiter[0]=1;
        if(!is_space[0] && (is_punctuation[0]==0 || (is_punctuation[0]==1 && (is_punctuation[1] ||
          is_space[1])))) is_delimiter[1]=1;
        if(is_delimiter[0]){
          if(buffer[i]=='*') can_open_close[0]=1;
          else if(is_delimiter[1]==0 || is_punctuation[0]==1) can_open_close[0]=1;
        }
        if(is_delimiter[1]){
          if(buffer[i]=='*') can_open_close[1]=1;
          else if(is_delimiter[0]==0 || is_punctuation[1]==1) can_open_close[1]=1;
        }
        for(int j=0;j<len;j++){
          if(j==0) inlines.incr_num().set(MK::emphasis,i,len);
          else inlines.incr_num().set(MK::none,i+len,0);
          inlines[end_MTS].len0_=len;
          inlines[end_MTS].can_start_=can_open_close[0];
          inlines[end_MTS].can_end_=can_open_close[1];
        }
        i+=len-1;
      }
      break;
      case '<':
      {
        int j=is_autolink(buffer,i,end,inlines,code_active);
        if(j!=-1){
          inlines.incr_num().set(MK::autolink,i,j,1);
          i=j;
          break;
        }
        j=is_html(buffer,i,end,inlines,code_active);
        if(j!=-1){
          inlines.incr_num().set(MK::html,i,j,1);
          i=j;
          break;
        }
      }
      break;
      case '!': case '[':
      {
        int j=this->is_link_or_image(buffer,i,end,inlines,code_active);
        if(j==-1) break;       
        if(buffer[i]=='!') inlines.incr_num().set(MK::image,i,j,1);
        else inlines.incr_num().set(MK::link,i,j,1);
        int pos=inlines.num()-1;
        
        check_set_code(buffer,ivec2(i,j),end,inlines,code_active);
        
        if(buffer[i]=='!') inlines.incr_num().set(MK::image,j,i,1);
        else inlines.incr_num().set(MK::link,j,i,1);
        inlines[end_MTS].i_alt_=pos;
        inlines[pos].i_alt_=inlines.num()-1;
        i=j;
      }
      break;
    }
  }
  
//################################################################################
//    search start end emphasis
//################################################################################
  
  int num_open=0; MyTSint6 opens;
  for(int i=0;i<inlines.num();i++){
    if(inlines[i].end_!=-1 && inlines[i].end_>inlines[i].start_ &&
      inlines[i].i_alt_!=-1){
      i=inlines[i].i_alt_;
      continue;
    }
    if(inlines[i].type_!=MK::emphasis) continue;
    if(inlines[i].len_>2){
      int delta=inlines[i].len_-2;
      inlines[i+1].type_=MK::emphasis;
      inlines[i+1].start_-=delta;
      inlines[i+1].len_+=delta;
      inlines[i].len_=2;
    }
    if(num_open>0 && inlines[i].can_end_){
      int found=0;
      for(int j=i-1;j>=0;j--){
        if(inlines[j].end_!=-1){
          if(inlines[j].end_<inlines[j].start_){
            j=inlines[j].i_alt_;
          }
          continue;
        }
        if(inlines[j].type_!=MK::emphasis) continue;
        if(buffer[inlines[j].start_]!=buffer[inlines[i].start_]) continue;
        if(!inlines[j].can_start_) continue;
        if(inlines[i].start_==inlines[j].start_+inlines[j].len_) break;
        if((inlines[j].can_start_ && inlines[j].can_end_) ||
          (inlines[i].can_start_ && inlines[i].can_end_)){
          if((inlines[i].len0_+inlines[j].len0_)%3==0 &&
            (inlines[i].len0_%3!=0 || inlines[j].len0_%3!=0)){
            continue;
          }
        }
        if(inlines[j].len_!=inlines[i].len_){
          if(inlines[j].len_>inlines[i].len_){
            if(inlines[j+1].end_==-1){
              inlines[j].len_-=inlines[i].len_;
              j++;
              inlines[j].start_-=inlines[i].len_;
              inlines[j].len_+=inlines[i].len_;
              inlines[j].type_=MK::emphasis;
            }
          } else {
            int delta=inlines[i].len_-inlines[j].len_;
            if(j>0 && inlines[j-1].type_==MK::emphasis && inlines[j-1].end_==-1 &&
              inlines[j].start_==inlines[j-1].start_+inlines[j-1].len_ &&
              inlines[j-1].len_>=delta){
              inlines[j-1].len_-=delta;
              inlines[j].start_-=delta;
              inlines[j].len_+=delta;
            } else {
              inlines[i].len_-=delta;
              inlines[i+1].start_-=delta;
              inlines[i+1].len_+=delta;
              inlines[i+1].type_=MK::emphasis;
            }
          }
        }
        if(inlines[j].len_!=inlines[i].len_) continue;
        num_open-=inlines[i].len_;
        inlines[j].end_=inlines[i].start_;
        inlines[i].end_=inlines[j].start_;
        inlines[j].i_alt_=i;
        inlines[i].i_alt_=j;
        found=1;
        break;
      }
      if(found) continue;
    }
    if(inlines[i].can_start_){
      num_open+=inlines[i].len_;
    }
  }
  
//################################################################################
//    clean unused
//################################################################################

  int prev_code_span=-1;
  for(int i=0;i<inlines.num();i++){
    if(inlines[i].end_==-1){
      inlines[i].type_=MK::none;
    } else if(inlines[i].type_==MK::code_span){
      if(prev_code_span==-1) prev_code_span=i;
      else prev_code_span=-1;
    } else if(prev_code_span!=-1){
      inlines[i].type_=MK::none;
      if(inlines[i].i_alt_!=-1){
        inlines[inlines[i].i_alt_].type_=MK::none;
      }
    } else if(inlines[i].type_==MK::link){
      int end_name=this->is_link_name(buffer,inlines[i].start_+1,end,0,
        inlines,code_active);
      int found=0;
      for(int j=i+1;j<inlines[i].i_alt_;j++){
        if(inlines[j].type_==MK::code_span && inlines[j].end_!=-1 &&
          (inlines[j].end_<inlines[i].start_ || inlines[j].end_>end_name)){
          found=1;
          break;
        }
      }
      if(found){
        inlines[i].type_=MK::none;
        if(inlines[i].i_alt_!=-1){
          inlines[inlines[i].i_alt_].type_=MK::none;
        }
      }
    }
  }
}

inline MarkdownStates give_inline_type(MyTSvec<MKinline,20>& inlines,
  int& curr_inline,int current)
{
  while(curr_inline<inlines.num() && (inlines[curr_inline].type_==MK::none ||
    inlines[curr_inline].start_<current)) curr_inline++;
  if(curr_inline<inlines.num() && inlines[curr_inline].start_==current){
    return inlines[curr_inline].type_;
  }
  return MK::none;
}

void MKstate::output_paragraph(MyTSchar& buffer,MyTSchar& out,int start,int end,
  int ibox,MyTSvec<MKinline,20>& inlines,int output_paraOpts)
{
  int c,used_quote=-1,curr_inline=0;
  
  for(int i=start;i<=end;i++){
    if(i>start && buffer[i-1]=='\n'){
      while(i<=end && is_chars(buffer[i],ASCII_space_g_)) i++;
      if(i>end) break;
      if(ibox!=-1){
        i=this->remove_block_quote_list_item_prefix(buffer,i,end,ibox);
      }
    }
    if(buffer[i]=='\\' && i<end){
      if(is_chars(buffer[i+1],ASCII_punctuation_g_) && 
        !(output_paraOpts&int(OPO::no_backslash_escapes))){
        output_quoted_char(out,buffer[i+1]);
        i++;
        continue;
      } else if(buffer[i+1]=='\n'){
        out.printE("<br />");
        continue;
      }
    }
    if(is_chars(buffer[i],"_*")){
      if(give_inline_type(inlines,curr_inline,i)==MK::emphasis){
        int nEnd=inlines[curr_inline].end_;
        int n=inlines[curr_inline].len_;
        if(n%2==1) out.printE("<em>");
        for(int j=0;j<n/2;j++) out.printE("<strong>");
        this->output_paragraph(buffer,out,i+n,nEnd-1,ibox,inlines,output_paraOpts);
        for(int j=0;j<n/2;j++) out.printE("</strong>");
        if(n%2==1) out.printE("</em>");
        i=nEnd+n-1;
        continue;
      }
    } else if(buffer[i]=='`'){
      if(give_inline_type(inlines,curr_inline,i)==MK::code_span){
        int nEnd=inlines[curr_inline].end_;
        int n=inlines[curr_inline].len_;
        out.printE("<code>");
        this->output_quoted_string_code_span(buffer,out,i+n,nEnd-1);
        out.printE("</code>");
        i=nEnd+n-1;
        continue;
      }
    } else if(buffer[i]=='^' && this->is_extension_active(EXT::superscript)){
      int n=1;
      int nEnd=find_closing_delimiterExact(buffer,i+n,end,buffer[i],n);
      if(nEnd!=-1){
        out.printE("<sup>");
        this->output_paragraph(buffer,out,i+n,nEnd-1,ibox);
        out.printE("</sup>");
        i=nEnd+n-1;
        continue;
      }
    } else if(buffer[i]=='~' && this->is_extension_active(EXT::subscript)){
      int n=1;
      int nEnd=find_closing_delimiterExact(buffer,i+n,end,buffer[i],n);
      if(nEnd!=-1){
        out.printE("<sub>");
        this->output_paragraph(buffer,out,i+n,nEnd-1,ibox);
        out.printE("</sub>");
        i=nEnd+n-1;
        continue;
      }
    } else if(buffer[i]=='$' && this->is_extension_active(EXT::tex_math_dollars)){
      int n=num_same_char_line_prefix(buffer,i,end,0);
      int nEnd=find_closing_delimiterExact(buffer,i+n,end,buffer[i],n);
      if(nEnd!=-1){
        if(n==1) out.printE("<span class='math inline'>\\(");
        else out.printE("<span class='math display'>\\[");
        this->output_quoted_string_code_span(buffer,out,i+n,nEnd-1);
        if(n==1) out.printE("\\)</span>");
        else out.printE("\\]</span>");
        i=nEnd+n-1;
        continue;
      }
    } else if(buffer[i]=='@' && this->is_extension_active(EXT::link_attributes)){
      const char* mA[2]; int mL[2];
      if(string_regexp(buffer.v(),i,end+1,"\\A@(\\w[-\\w:]*)",mA,mL,2)==1){
        MyTSchar id;
        id.setV(mA[1],mL[1]);
        if(this->give_by_id(id.v())){
          out.printE("%s",this->give_by_id(id.v())->number_.v());
          i+=mL[0]-1;
          continue;
        }
      }
    } else if(buffer.regexp(i,"\\A(\\[|!\\[)")){
      MyTSchar name,text,url,title;
      int c=i;
      if(buffer[i]=='!') c++;
      
      if(is_link_image(give_inline_type(inlines,curr_inline,i))){
        c=link_text(buffer,c,end,text);;
      } else {
        c=0;
      }
      if(c!=0){
        if(c<=end && buffer[c]=='('){
          int c0=c;
          c++;
          int c_alt=link_destination(buffer,c,url);
          if(c_alt!=0) c=c_alt;
          c_alt=link_title(buffer,c,title);
          if(c_alt!=0) c=c_alt;
          while(c<buffer.num() && is_chars(buffer[c],ASCII_space_g_)) c++;
          if(buffer[c]!=')') c=0;
          else c++;
          if(c==0){
            name=text;
            link_normalize(name);
            if(name.num()==0) c=0;
            else c=c0;
          }
        } else if(c<=end && buffer[c]=='['){
          c++;
          if(buffer[c]==']'){
            name=text;
            c++;
          } else {
            c=link_label_name(buffer,c-1,name);
          }
          if(c){
            link_normalize(name);
            if(name.num()==0) c=0;
          }
        } else {
          name=text;
          link_normalize(name);
          if(name.num()==0) c=0;
        }
      }
      int iboxREF=ibox;
      if(c!=0 && name.num()!=0){
        MKlink* link=links_.getH(name.v());
        if(!link){
          c=0;
        } else {
          url=link->url_;
          title=link->title_;
          iboxREF=link->ibox_;
        }
      }
      if(c!=0){ 
        replace_backslash(url);
        replace_backslash(title);
        replace_backslash(text);
        if(buffer[i]=='!'){
          this->output_image(iboxREF,buffer,out,url,title,text,ibox);
        } else {
          this->output_link(out,url,title,text,ibox);
        }
        i=c-1;
        continue;
      }
    } else if(buffer[i]=='<'){
      if(give_inline_type(inlines,curr_inline,i)==MK::autolink){
        MyTSchar name,text,url,title;
        c=inlines[curr_inline].end_;
        url.setV(&buffer[i+1],c-i-1);
        text.setV(&buffer[i+1],c-i-1);
        
        const char* rex="([a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]"
          "(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
          "(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)";
        if(url.regexp(0,rex)==1 && url.regexp(0,"(?i)^mailto:")==0){
          MyTSchar tmp=url;
          url.print0("mailto:%s",tmp.v());
        }
        
        this->output_link(out,url,title,text,ibox,0);
        i=c;
        continue;
      } else if(give_inline_type(inlines,curr_inline,i)==MK::html){
        c=inlines[curr_inline].end_;
        for(int j=i;j<=c;j++){
          out.printE("%c",buffer[j]);
        }
        i=c;
        continue;
      }
    } else if(i==used_quote){
      output_quoted_string(out,"\xe2\x80\x9d");
      continue;
    } else if(buffer[i]=='"' && used_quote!=i && this->is_extension_active(EXT::smart)){
      int found=0;
      for(int j=i+1;j<=end;j++){
        if(buffer[j]=='"' && buffer[j-1]!='\\'){
          found=1;
          used_quote=j;
          break;
        }
      }
      if(found){
        output_quoted_string(out,"\xe2\x80\x9c");
        continue;
      }
    }
      
    if(buffer[i]=='\n'){
      if(output_paraOpts&int(OPO::endline_to_space)){
        output_quoted_char(out,' ');
      } else {
        output_quoted_char(out,'\n');
      }
    } else if(buffer[i]==' '){
      int num_spaces;
      int c=spaces_num(buffer,i,&num_spaces);
      if(num_spaces>=2 && c<=end && buffer[c]=='\n'){
        out.printE("<br />\n");
        i=c;
      } else if(num_spaces==1 && c<=end && buffer[c]=='\n'){
        // nothing
      } else {
        output_quoted_char(out,buffer[i]);
      }
    } else if(buffer[i]=='&'){
      int c=entities_json_to_c(buffer,out,i);
      if(c!=-1){
        i=c;
      } else {
        output_quoted_char(out,buffer[i]);
      }
    } else {
      output_quoted_char(out,buffer[i]);
    }
  }
}

void MKstate::output_paragraph(MyTSchar& buffer,MyTSchar& out,int start,int end,
  int ibox,int output_paraOpts)
{
  MyTSvec<MKinline,20> inlines;
  this->parse_inlines(buffer,start,end,inlines,output_paraOpts);
  this->output_paragraph(buffer,out,start,end,ibox,inlines,output_paraOpts);
}

void MKstate::output_paragraph(MyTSchar& buffer,MyTSchar& out,int ibox)
{
  if(blocks_[ibox].posNoBlank_[0]==-1) return;
  this->output_paragraph(buffer,out,blocks_[ibox].posNoBlank_[0],
    blocks_[ibox].posNoBlank_[1],ibox);
}

void MKstate::output_paragraph_all_spaces(MyTSchar& buffer,int start,int end,
  MyTSchar& out,int ibox,int print_endline,int num_indent_spaces_removed,
  int check_remove_start)
{  
  if(check_remove_start){
    start=this->remove_block_quote_list_item_prefix(buffer,start,end,ibox);
  }
  for(int i=start;i<=end;i++){
    if(i>start && buffer[i-1]=='\n'){
      i=this->remove_block_quote_list_item_prefix(buffer,i,end,ibox);
      if(i>end) break;
    }
    if(num_indent_spaces_removed>0 && (i==start || buffer[i-1]=='\n')){
      int n=0;
      while(i<=end && buffer[i]==' '){
        n++;
        i++;
        if(n==num_indent_spaces_removed) break;
      }
    }
    output_quoted_char(out,buffer[i]);
  }
  if(print_endline){
    for(int i=blocks_[ibox].posNoBlank_[1]+1;i<=blocks_[ibox].pos_[1];i++){
      output_quoted_char(out,buffer[i]);
    }
  }
}

void MKstate::output_paragraph_no_quoted(MyTSchar& buffer,MyTSchar& out,int ibox)
{
  int start=blocks_[ibox].posNoBlank_[0];
  if(start==-1) return;
  int end=blocks_[ibox].posNoBlank_[1];
  
  for(int i=start;i<=end;i++){
    if(i>start && buffer[i-1]=='\n'){
      i=this->remove_block_quote_list_item_prefix(buffer,i,end,ibox);
    }
    out.printE("%c",buffer[i]);
  }
  if(buffer[end]!='\n') out.printE("\n");
}

int MKstate::is_loose_last(int iblock)
{
  if(blocks_[iblock].mtype_==MK::block_quote) return 0;
  if(blocks_[iblock].tight_==0) return 1;
  if(blocks_[iblock].children_.num()){
    int child=blocks_[iblock].children_[end_MTS];
    return this->is_loose_last(child);
  }
  return 0;
}

inline void force_line_start(MyTSchar& out)
{
  if(out.num() && out[end_MTS]!='\n') out.printE("\n");
}

// numbering will return -1,0,1
static int manage_link_attributes(const char* buffer,MyTSchar* out,
  MyTSchar* id,MyTSchar* fileName,int* numbering,MyTSchar* display,MyTSchar* create,
  const char* add_class)
{ 
  const char* mA[3]; int mL[3]; MyTSchar str;
  if(string_regexp(buffer,0,-1,"^\\s*\\{([^}]*)\\}",mA,mL,2)==0) return 0;
  MyTScharList words,classes;
  str.setV(mA[1],mL[1]);
  string_split(str.v(),"\\s+",words);
  for(int i=0;i<words.num();i++){
    if(string_regexp(words[i].v(),0,-1,"^\\.(.*)",mA,mL,2)){
      classes.incr_num().setV(mA[1],mL[1]);
    } else if(string_regexp(words[i].v(),0,-1,"^#(.*)",mA,mL,2)){
      if(id) id->setV(&words[i][1],-1);
      if(out) out->printE(" id='%s'",string_quote_xml(words[i],1));
    } else if(string_regexp(words[i].v(),0,-1,"(.*)=(.*)",mA,mL,3)){
      MyTSchar name; name.setV(mA[1],mL[1]);
      MyTSchar value; value.setV(mA[2],mL[2]);
      value.regsub(0,"(^['\"])|(['\"]$)","");
      if(strcmp(name.v(),"file")==0){
        if(fileName) *fileName=value;
      }
      if(strcmp(name.v(),"display")==0){
        if(display) *display=value;
      }
      if(strcmp(name.v(),"create")==0){
        if(create) *create=value;
      }
      if(out) out->printE(" data-%s='%s'",string_quote_xml(name),
        string_quote_xml(value));
    }
  }
  
  if(numbering) *numbering=-1;
  
  if(add_class){
    classes.incr_num()=add_class;
  }
  
  for(int i=0;i<classes.num();i++){
    if(numbering && strcmp(classes[i].v(),"numbered")==0) *numbering=1;
    if(numbering && strcmp(classes[i].v(),"unnumbered")==0) *numbering=0;
    if(i==0){
      if(out) out->printE(" class='");
    } else {
      if(out) out->printE(" ");
    }
    if(out) out->printE("%s",string_quote_xml(classes[i]));
    if(i==classes.num()-1){
      if(out) out->printE("'");
    }
  }
  return 1;
}

static void parse_todo_txt(const char* line,int& completed,MyTSchar& completed_date,
  MyTSchar& priority,MyTSchar& date,MyTSchar& desc,MyTSchar& projects,MyTScharListH& keyvalues)
{
  const char* mA[3]; int mL[3];
  MyTSchar name;
  
  completed_date.clear();
  
  int c=0;
  if(string_regexp(line,c,-1,"\\A\\s*x",mA,mL,1)){
    completed=1;
    c=mA[0]-line+mL[0];
    
    if(string_regexp(line,c,-1,"\\A\\s*(\\d{4}-\\d{2}-\\d{2})",mA,mL,2)){
      completed_date.setV(mA[1],mL[1]);
      c=mA[0]-line+mL[0];
    }
  } else {
    completed=0;
  }
  if(string_regexp(line,c,-1,"\\A\\s*\\(([A-Z])\\)",mA,mL,2)){
    priority.setV(mA[1],mL[1]);
    c=mA[0]-line+mL[0];
  } else {
    priority.clear();
  }
  if(string_regexp(line,c,-1,"\\A\\s*(\\d{4}-\\d{2}-\\d{2})",mA,mL,2)){
    date.setV(mA[1],mL[1]);
    c=mA[0]-line+mL[0];
  } else {
    date.clear();
  }
  desc.setV(&line[c],-1);
  
  keyvalues.remove();
  c=0;
  while(string_regexp(desc.v(),c,-1,"(?:^|[^+@])([-\\w]+):(\\S+)",mA,mL,3)){
    name.setV(mA[1],mL[1]);
    keyvalues.appendH(name.v()).setV(mA[2],mL[2]);
    c=mA[0]-desc.v();
    desc.clear(c,mL[0]);
  }
  
  projects.clear();
  c=0; int c_start=-1;
  while(string_regexp(desc.v(),c,-1,"\\+(\\S+)",mA,mL,2)){
    if(projects.num()>0) projects.printE(" ");
    projects.appendV(mA[1],mL[1]);
    if(c_start==-1) c_start=mA[0]-desc.v();
    c=mA[0]-desc.v()+mL[0];
  }
  if(c_start!=-1 && string_regexp(desc.v(),c,-1,"\\s*$")){
    desc.print(c_start,"");
  }
  desc.regsub(0,"^\\s+|\\s+$","");
}

static void sha1_todo_txt(int& completed,MyTSchar& completed_date,
  MyTSchar& priority,MyTSchar& date,MyTSchar& desc,MyTSchar& projects,
  MyTScharListH& keyvalues,MyTSchar& sha1key)
{
  MyTScharList list,keyList;
  MyTSchar data;
  MyTSuchar data_res(20);
  
  if(completed) list.appendList("1",NULL);
  else list.appendList("0",NULL);
  list.appendList(completed_date.v(),completed_date.v(),completed_date.v(),
    priority.v(),date.v(),desc.v(),projects.v(),NULL);
  int search_id=-1; const char* name; ggclong pos;
  while((pos=keyvalues.Mytextlongtable::nextv(search_id,name))!=-1){
    if(strcmp(name,"sha1")==0) continue;
    keyList.incr_num()=name;
  }
  keyList.sort();
  for(int i=0;i<keyList.num();i++){
    pos=keyvalues.Mytextlongtable::get(keyList[i].v());
    list.appendList(keyList[i].v(),keyvalues[pos].v(),NULL);
  }
  string_create_tcl_list(list,data);  
  sha1key.set_num(20);
  sha1((unsigned char*) data.v(),data.num(),data_res.v());
  
  sha1key.clear();
  for(int i=0;i<5;i++){
    sha1key.printE("%02x",data_res[i]);
  }
  if(0) printf("%s %s\n",data.v(),sha1key.v());
}

static void create_todo_txt(int& completed,MyTSchar& completed_date,
  MyTSchar& priority,MyTSchar& date,MyTSchar& desc,MyTSchar& projects,
  MyTScharListH& keyvalues,MyTSchar& line)
{
  MyTSchar sha1;
  sha1_todo_txt(completed,completed_date,priority,date,desc,projects,
    keyvalues,sha1);
  keyvalues.getF_H("sha1")=sha1;
    
  line.clear();
  if(completed){
    line.printE("x");
    if(completed_date.num()) line.printE(" %s",completed_date.v());
  }
  if(priority.v()){
    if(!completed){
      if(line.num()) line.printE(" ");
      line.printE("(%s)",priority.v());
    } else {
      keyvalues.getF_H("pri")=priority;
    }
  }
  if(date.num()){
    if(line.num()) line.printE(" ");
    line.printE("%s",date.v());
  }
  if(desc.num()){
    if(line.num()) line.printE(" ");
    line.printE("%s",desc.v());
  }
  if(projects.num()){
    if(line.num()) line.printE(" ");
    line.printE("+%s",projects.v());
  }
  int search_id=-1; const char* name; ggclong pos;
  while((pos=keyvalues.Mytextlongtable::nextv(search_id,name))!=-1){
    if(line.num()) line.printE(" ");
    line.printE("%s:%s",name,keyvalues[pos].v());
  }  
}

static int sort_todo_txt(const void* p1,const void* p2,void *arg)
{
  MyTScharList& lines=*(MyTScharList*) arg;
  MyTSchar& c1=lines[*(int*)p1];
  MyTSchar& c2=lines[*(int*)p2];
  
  ivec2 completed; MyTSchar completed_date[2],priority[2],date[2],desc[2],projects[2];
  MyTScharListH keyvalues[2];
  parse_todo_txt(c1.v(),completed[0],completed_date[0],priority[0],date[0],desc[0],projects[0],
    keyvalues[0]);
  parse_todo_txt(c2.v(),completed[1],completed_date[1],priority[1],date[1],desc[1],projects[1],
    keyvalues[1]);
  
  if(strcmp(projects[0].v(),projects[1].v())!=0){
    return strcmp(projects[0].v(),projects[1].v());
  }

  if(completed[0]<completed[1]) return -1;
  else if(completed[0]>completed[1]) return 1;
  
  if(priority[0].num()){
    if(priority[1].num()){
      int ret=strcmp(priority[0].v(),priority[1].v());
      if(ret!=0) return ret;
    } else {
      return -1;
    }
  } else if(priority[1].num()){
    return 1;
  }
  return strcmp(desc[0].v(),desc[1].v());
}

void MKstate::fill_table_from_file(const char* fileName,
  MyTScharList& align,MyTSchar& out)
{
  int completed;
  MyTSchar data,completed_date,priority,date,desc,projects,projects_prev;
  MyTScharListH keyvalues;
  
  try { read_fileG(fileName,data,0); }
  catch(MyTSchar& c){
    UNUSED(c);
    return;
  }
  if(string_regexp(fileName,0,-1,".todo.txt$")){
    MyTScharList lines; MyTSint linesP;
    string_split(data.v(),"\n",lines);
    projects_prev.clear();
    for(int i=0;i<lines.num();i++) linesP.append(i);
    linesP.sort_r(sort_todo_txt,&lines);
    if(align.num()<4) align.set_num(4);
    for(int i=0;i<linesP.num();i++){
      parse_todo_txt(lines[linesP[i]].v(),completed,completed_date,priority,
        date,desc,projects,keyvalues);
      if(strcmp(projects.v(),projects_prev.v())!=0){
        projects_prev=projects;
        out.printE("</tbody><thead>");
        out.printE("<tr><th colspan='4'>%s</th></tr>\n",
          string_quote_xml(projects));
        out.printE("</thead><tbody>");
      }
      out.printE("<tr>\n");
      for(int j=0;j<4;j++){
        if(align[j].num()==0){
          out.printE("<td>");
        } else {
          out.printE("<td style='text-align: %s;'>",align[j].v());
        }
        switch(j){
          case 0: out.printE((completed)?"<strong>x</strong>":""); break;
          case 1: out.printE(((priority.num())?"<strong>%s</strong>":""),
            priority.v()); break;
          case 2:
          {
            this->output_paragraph(desc,out,0,desc.num()-1,-1);
          }
          break;
          case 3: out.printE("%s",date.v()); break;
        }
        out.printE("</td>");
      }
      out.printE("</tr>\n");
    }
  }
}

int MKstate::is_fenced_block_info_string(MyTSchar& buffer,int start,
  MyTSchar& infostring)
{
  infostring.clear();
  for(int i=start;i<buffer.num();i++){
    if(buffer[i]=='{') return 0;
    int pos=this->entities_json_to_c(buffer,infostring,i);
    if(pos!=-1){
      i=pos;
      continue;
    }
    if(buffer[i]=='\n'){
      if(infostring.num()) return 1;
      else return 0;
    } else if(is_chars(buffer[i],ASCII_space_g_)){
      if(infostring.num()>0) return 1;
    } else if(buffer[i]=='\\' && i<buffer.num()-1){
      infostring.append(buffer[i+1]);
      i++;
    } else {
      infostring.append(buffer[i]);
    }
  }
  if(infostring.num()) return 1;
  else return 0;
}

void MKstate::init_rdinfo_lineNum(MyTSchar& out)
{
  lineNum_=1; 
  lineNum_pos_=-1;
  out.printE("0 n");
}

void MKstate::update_rdinfo_lineNum(MyTSchar& buffer,MyTSchar& out,int start)
{
  for(int i=lineNum_pos_+1;i<start;i++){
    if(buffer[i]=='\n'){
      out.printE("\n0 n");
      //out.printE("\n0 n orange %d %d",lineNum_+1,lineNum_+1);
      lineNum_pos_=i;
      lineNum_++;
    }
  }
}

void MKstate::output_markdown_start(MyTSchar& buffer,MyTSchar& out)
{
  if(otype_==OT::rdinfo){
    this->init_rdinfo_lineNum(out);
  } else {
    if(this->is_extension_active(EXT::metadata_block)){
      out.printE(""
        "<!DOCTYPE html>\n"
        "<html xmlns='http://www.w3.org/1999/xhtml' lang='en' xml:lang='%s'>\n"
        "<head>\n"
        "<meta charset='utf-8' />\n"
        "<meta name='generator' content='svgml' />\n"
        "<meta name='viewport' content='width=device-width, initial-scale=1.0, user-scalable=yes' />\n"
        "<meta name='author' content='%s' />\n"
        "<meta name='dcterms.date' content='%s' />\n"
        "<meta name='keywords' content='%s' />\n"
        "<title>%s</title>\n"
        "<style>\n"
        "code{white-space: pre-wrap;}\n"
        "span.smallcaps{font-variant: small-caps;}\n"
        "span.underline{text-decoration: underline;}\n"
        "div.column{display: inline-block; vertical-align: top; width: 50%;}\n"
        "</style>\n"
        "<link rel='stylesheet' href='%s' />\n"
        "<script src='https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.2/MathJax.js?config=TeX-AMS_CHTML-full' "
        "type='text/javascript'></script>\n"
        "<!--[if lt IE 9]>\n"
        "<script src='//cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv-printshiv.min.js'></script>\n"
        "<![endif]-->\n"
        "</head>\n"
        "<body>\n",
        string_quote_xml(metadata_.getF_H("lang")),
        string_quote_xml(metadata_.getF_H("author")),
        string_quote_xml(metadata_.getF_H("date")),
        string_quote_xml(metadata_.getF_H("keywords")),
        string_quote_xml(metadata_.getF_H("title")),
        string_quote_xml(metadata_.getF_H("css"))
        );
    } else if(this->is_extension_active(EXT::full_html)){
      out.printE("<html>\n<body>\n");
    }
  }
  this->output_markdown(buffer,out,0);
  if(otype_==OT::rdinfo){
    this->update_rdinfo_lineNum(buffer,out,buffer.num());
  } else if(this->is_extension_active(EXT::full_html)){
    out.printE("\n</body>\n</html>\n");
  }
}

void MKstate::output_markdown(MyTSchar& buffer,MyTSchar& out,int iblock)
{
  switch(blocks_[iblock].mtype_){
    case MK::document:
    {
      // nothing
    }
    break;
    case MK::indented_code_block:
    {
      if(otype_==OT::html){
        int out_num=-1;
        int iblock_prev=this->give_prev(iblock);
        if(iblock_prev==-1 || blocks_[iblock_prev].mtype_!=MK::indented_code_block){
          force_line_start(out);
          out.printE("<pre><code>");
          out_num=out.num();
        } else {
          int pos0=blocks_[iblock_prev].pos_[1]+1;
          int len=blocks_[iblock].pos_[0];
          int n=string_regexp_count(buffer.v(),pos0,len,"\n");
          for(int i=0;i<n;i++){
            out.printE("\n");
          }
        }
        int start=blocks_[iblock].posNoBlank_[0];
        int end=blocks_[iblock].posNoBlank_[1];
        this->output_paragraph_all_spaces(buffer,start,end,out,iblock,1,0,0);
        int iblock_next=this->give_next(iblock);
        if(iblock_next==-1 || blocks_[iblock_next].mtype_!=MK::indented_code_block){
          if(out[end_MTS]!='\n' && out_num!=out.num()) out.printE("\n");
          out.printE("</code></pre>\n");
        }
      }
    }
    break;
    case MK::fenced_code_block:
    {
      MyTSchar rdinfo,fileName,display,create;
      int out_num=-1;
      
      int c0=blocks_[iblock].pos_[0];
      int c1=blocks_[iblock].posNoBlank_[0]-1;
      int is_svgml=0,do_output=1;
      if(string_regexp(buffer.v(),c0,c1,"svgml")==1){
        is_svgml=1;
        int c=spaces_num(buffer,c0);
        c+=num_same_char_line_prefix(buffer,c,c1,0);
        manage_link_attributes(&buffer[c],NULL,NULL,NULL,NULL,&display,&create);
        if(strcmp(display.v(),"1")==0){
          do_output=1;
        } else if(strcmp(display.v(),"0")==0){
          do_output=0;
        } else if(this->is_extension_active(EXT::hide_svgml)){
          do_output=0;
        }
      }
      
      //int iblock_prev=this->give_prev(iblock);
      int iblock_prev=-1;
      if(iblock_prev==-1 || blocks_[iblock_prev].mtype_!=MK::fenced_code_block){
        int c=spaces_num(buffer,blocks_[iblock].pos_[0]);
        c+=num_same_char_line_prefix(buffer,c,blocks_[iblock].pos_[1],0);
        if(otype_==OT::html){
          if(do_output) force_line_start(out);
          MyTSchar infostring;
          if(this->is_fenced_block_info_string(buffer,c,infostring)){
            if(do_output) out.printE("<pre><code class=\"language-%s\">",infostring.v());
          } else {
            if(do_output)out.printE("<pre");
            if(this->is_extension_active(EXT::link_attributes)){
              manage_link_attributes(&buffer[c],(do_output)?&out:NULL,NULL,&fileName);
            }
            if(do_output) out.printE("><code>");
          }
          out_num=out.num();
        }
      }
      
      this->update_rdinfo_lineNum(buffer,rdinfo,c0);
      rdinfo.printE(" green %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);

      if(otype_==OT::html) rdinfo.clear();
      
      int num_spaces=0;
      int iblock0=iblock;
      while(1){
        int iblock0L=this->give_prev(iblock0);
        if(iblock0L==-1) break;
        iblock0=iblock0L;
      }
      int pos=spaces_num(buffer,blocks_[iblock0].pos_[0]);
      num_spaces=pos-blocks_[iblock0].pos_[0];
      
      int start=blocks_[iblock].posNoBlank_[0];
      int end=blocks_[iblock].posNoBlank_[1];
      
      if(is_svgml){
        int create_svg=1,create_gid=0;
        if(create.regexp(0,"1|svg")){
          create_svg=1;
        } else if(create.regexp(0,"0|gid")){
          create_svg=0;
        }
        if(create.regexp(0,"gid")){
          create_gid=1;
        }
        MyTSchar data;
        if(fileName.num() && create_svg!=0){
          svgml_process(OTS::svg,buffer,data,start,end,lineNum_,lineNum_pos_,
            NULL,this);
          try { write_fileG_if_different(fileName.v(),data.v(),1); }
          catch(MyTSchar& c){
            fprintf(stderr,"%s\n",c.v());
          }
        }
        if(fileName.num() && create_gid!=0){
          MyTScharList cmdList;
          cmdList.setList("file","normalize",fileName.v(),NULL);
          this->check_init_ip();
          MyTSchar geoFile=eval_tcl(ip_,cmdList);
          file_root(geoFile);
          MyTSchar tail=file_tail(geoFile.v());
          geoFile.printE(".gid/%s.geo",tail.v());
          data.clear();
          svgml_process(OTS::gid,buffer,data,start,end,lineNum_,lineNum_pos_,
            geoFile.v(),this);
          try { 
            this->create_gid_file(geoFile.v(),data.v());
          }
          catch(MyTSchar& c){
            fprintf(stderr,"%s\n",c.v());
            throw;
          }
        }
        svgml_process(OTS::rdinfo,buffer,rdinfo,start,end,lineNum_,lineNum_pos_,
          NULL,this);
      } else {          
        for(int i=start;i<=end;i++){
          int startL=i;
          int endAL=i;
          while(endAL<end && buffer[endAL]!='\n') endAL++;
          const char* mA[2]; int mL[2];
          const char* rex="^\\s*(\\S.*\\S)\\s*$";
          if(string_regexp(buffer.v(),startL,endAL,rex,mA,mL,2)==1){
            int c0=mA[1]-buffer.v();
            int c1=mA[1]-buffer.v()+mL[1];
            this->update_rdinfo_lineNum(buffer,rdinfo,c0);
            rdinfo.printE(" grey %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
          }
        }
      }
      c0=blocks_[iblock].posNoBlank_[1]+1;
      c1=blocks_[iblock].pos_[1];
      this->update_rdinfo_lineNum(buffer,rdinfo,c0);
      rdinfo.printE(" green %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
      
      if(otype_==OT::rdinfo){
        out.appendV(rdinfo.v(),rdinfo.num());
      } else if(!is_svgml){
        int start=blocks_[iblock].posNoBlank_[0];
        if(start!=-1){
          int end=blocks_[iblock].posNoBlank_[1];
          this->output_paragraph_all_spaces(buffer,start,end,out,iblock,0,
            num_spaces,1);
        }
      } else if(do_output){
        int start=blocks_[iblock].posNoBlank_[0];
        int startLine=start;
        int end=blocks_[iblock].posNoBlank_[1];

        MyTScharList lines,words;
        string_split_text_sep(rdinfo.v(),-1,"\n",lines);
        for(int i=1;i<lines.num();i++){
          string_split_text_sep(lines[i].v(),-1," ",words);
          for(int j=2;j<words.num();j+=3){
            const char* color=words[j].v();
            int pos1=startLine+atoi(words[j+1].v());
            int pos2=startLine+atoi(words[j+2].v());
            output_quoted_string_nobackslash(buffer,out,start,pos1-1);
            out.printE("<span style='color:%s;'>",color);
            start=pos1;
            output_quoted_string_nobackslash(buffer,out,start,pos2-1);
            start=pos2;
            out.printE("</span>");
          }
          char* p=strchr(&buffer[start],'\n');
          if(p) startLine=p-buffer.v()+1;
          else startLine=buffer.num();
          output_quoted_string_nobackslash(buffer,out,start,startLine-1);
          start=startLine;
          if(start>=buffer.num() || start>end) break;
        }
      }
      //int iblock_next=this->give_next(iblock);
      int iblock_next=-1;
      if(iblock_next==-1 || blocks_[iblock_next].mtype_!=MK::fenced_code_block){
        if(otype_==OT::html && do_output){
          if(out[end_MTS]!='\n' && out_num!=out.num()) out.printE("\n");
          out.printE("</code></pre>\n");
        }
      }
    }
    break;
    case MK::HTML_block:
    {
      if(otype_==OT::html){
        force_line_start(out);
        this->output_paragraph_no_quoted(buffer,out,iblock);
      } else {
        int c0=blocks_[iblock].posNoBlank_[0];
        int c1=blocks_[iblock].posNoBlank_[1]+1;
        this->update_rdinfo_lineNum(buffer,out,c0);
        if(buffer.regexp(c0,"\\A<!--")){
          out.printE(" red %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
        } else {
          out.printE(" grey %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
        }
      }
    }
    break;
    case MK::link_reference_definition:
    {
      // nothing
    }
    break;
    case MK::block_quote:
    {
      if(otype_==OT::html){
        force_line_start(out);
        out.printE("<blockquote>\n");
      }
    }
    break;
    case MK::list_item:
    {
      int need_start=0;
      int iblock_prev=this->give_prev(iblock);
      if(iblock_prev==-1 || blocks_[iblock_prev].mtype_!=MK::list_item){
        need_start=1;
      } else {
        MyTSchar matches1[4],matches2[4];
        const char* rex="^\\s*(?:(\\d{1,9})([.\\)])|([-+*]))";
        buffer.regexp(blocks_[iblock_prev].pos_[0],rex,matches1,4);
        buffer.regexp(blocks_[iblock].pos_[0],rex,matches2,4);
        need_start=1;
        if(matches1[2].num() && matches2[2].num() && matches1[2][0]==matches2[2][0]){
          need_start=0;
        } else if(matches1[3].num() && matches2[3].num() && matches1[3][0]==matches2[3][0]){
          need_start=0;
        }
        if(need_start){
          if(otype_==OT::html){
            if(matches1[2].num()){
              out.printE("</ol>\n");
            } else {
              out.printE("</ul>\n");
            }
          }
        }
      }
      
      if(need_start){
        MyTSchar iblocks;
        iblocks.append(iblock);
        while(1){
          int iblock_next=this->give_next(iblocks[end_MTS]);
          if(iblock_next==-1 || blocks_[iblock_next].mtype_!=MK::list_item){
            break;
          }
          iblocks.append(iblock_next);
        }
        int tight=1;
        for(int i=0;i<iblocks.num()-1;i++){
          if(blocks_[iblocks[i]].tight_==0){
            tight=0;
            break;
          }
          if(this->is_loose_last(iblocks[i])){
            tight=0;
            break;
          }
        }
        for(int i=0;i<iblocks.num();i++){
          if(blocks_[iblocks[i]].children_.num()>1){
            for(int j=0;j<blocks_[iblocks[i]].children_.num()-1;j++){
              int child=blocks_[iblocks[i]].children_[j];
              if(this->is_loose_last(child)){
                tight=0;
                break;
              }
            }
          }
        }
        for(int i=0;i<iblocks.num();i++){
          blocks_[iblocks[i]].tight_=tight;
          if(blocks_[iblocks[i]].children_.num()>1){
            for(int j=0;j<blocks_[iblocks[i]].children_.num()-1;j++){
              int child=blocks_[iblocks[i]].children_[j];
              if(blocks_[child].tight_==0){
                blocks_[iblocks[i]].tight_=0;
                break;
              }
            }
          }
        }
        MyTSchar matches[2];
        if(buffer.regexp(blocks_[iblock].pos_[0],"^\\s*(\\d{1,9})[.\\)]",matches,2)){
          while(matches[1].num()>1 && matches[1][0]=='0') matches[1].clear(0);
          if(otype_==OT::html){
            force_line_start(out);
            if(strcmp(matches[1].v(),"1")==0){
              out.printE("<ol>\n");
            } else {
              out.printE("<ol start=\"%s\">\n",matches[1].v());
            }
          }
        } else {
          if(otype_==OT::html){
            force_line_start(out);
            out.printE("<ul>\n");
          }
        }
      }
      if(otype_==OT::html){
        out.printE("<li>");
      }
    }
    break;
    case MK::ATX_heading: case MK::setext_heading:
    {
      if(otype_==OT::html){
        force_line_start(out);
        out.printE("<h%d",blocks_[iblock].level_);
        
        MyTSchar id; int numbering=-1;
        if(this->is_extension_active(EXT::link_attributes)){
          manage_link_attributes(&buffer[blocks_[iblock].posNoBlank_[1]+1],&out,
            &id,NULL,&numbering);
        }
        out.printE(">");
        
        if(numbering!=0 && id.num()==0){
          id.print0("heading %d",blocks_[iblock].number_);
        }        
        if(id.num() && numbering!=0){
          MKid* mkid=idsG_.getH(id.v());
          if(mkid && mkid->number_.num()){
            out.printE("%s ",mkid->number_.v());
          }
        }
        this->output_paragraph(buffer,out,iblock);
        out.printE("</h%d>\n",blocks_[iblock].level_);
      } else {
        int c0=blocks_[iblock].pos_[0];
        int c1=blocks_[iblock].posNoBlank_[0]-1;
        this->update_rdinfo_lineNum(buffer,out,c0);
        out.printE(" magenta %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
        c0=blocks_[iblock].posNoBlank_[0];
        c1=blocks_[iblock].posNoBlank_[1]+1;
        out.printE(" blue %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
      }
    }
    break;
    case MK::thematic_break:
    {
      if(otype_==OT::html){
        force_line_start(out);
        out.printE("<hr />\n");
      }
    }
    break;
    case MK::definition_lists:
    {
      const char* mA[3]; int mL[3];
      if(otype_==OT::html){
        int iblock_prev=this->give_prev(iblock);
        if(iblock_prev!=-1 && blocks_[iblock_prev].mtype_==MK::none){
          iblock_prev=this->give_prev(iblock_prev);
        }
        if(iblock_prev==-1 || blocks_[iblock_prev].mtype_!=MK::definition_lists){
          out.printE("<dl>\n");
        }
        int start=blocks_[iblock].posNoBlank_[0];
        int end=blocks_[iblock].posNoBlank_[1];
        string_regexp(buffer.v(),start,end+1,"^\\s*(\\S[^\n]*)\n\\s*:(.*)",mA,mL,3);
        out.printE("<dt>");
        start=mA[1]-buffer.v();
        end=mA[1]-buffer.v()+mL[1]-1;
        this->output_paragraph(buffer,out,start,end,iblock);
        out.printE("</dt>\n<dd><p>");
        start=mA[2]-buffer.v();
        end=mA[2]-buffer.v()+mL[2]-1;
        this->output_paragraph(buffer,out,start,end,iblock);
        out.printE("</p></dd>\n");
        int iblock_next=this->give_next((iblock));
        if(iblock_next!=-1 && blocks_[iblock_next].mtype_==MK::none){
          iblock_next=this->give_next(iblock_next);
        }
        if(iblock_next==-1 || blocks_[iblock_next].mtype_!=MK::definition_lists){
          out.printE("</dl>\n");
        }
      }
    }
    break;
    case MK::pipe_table:
    {
      if(otype_==OT::html){
        int start=blocks_[iblock].posNoBlank_[0];
        int end=blocks_[iblock].posNoBlank_[1];
        MyTScharList rows,cols,align; int tableMax=0;
        string_split(&buffer[start],end-start+1,"\n",rows);
        string_split(rows[1].v(),"\\s*\\|\\s*",cols);
        MyTSint6 weights; int weightTot=0;
        align.set_num(cols.num());
        for(int i=0;i<cols.num();i++){
          if((i==0 || i==cols.num()-1) && cols[i].regexp(0,"^\\s*$")){
            cols.clear(i); i--; continue;
          }
          int n=string_regexp_count(cols[i].v(),0,-1,"-");
          weights.set_at(i,n);
          weightTot+=n;
          if(string_regexp(cols[i].v(),0,-1,":-+:")){
            align.getF(i)="center";
            tableMax=1;
          } else if(string_regexp(cols[i].v(),0,-1,"^\\s*:-+")){
            align.getF(i)="left";
          } else if(string_regexp(cols[i].v(),0,-1,"-+:\\s*$")){
            align.getF(i)="right";
          }
        }
        int num_columns=cols.num();
        
        MyTSchar fileName,id; int numbering=-1;
        int c=blocks_[iblock].posNoBlank_[1]+1;
        int has_attributes=manage_link_attributes(&buffer[c],NULL,
          &id,&fileName,&numbering);
        if(has_attributes){
          out.printE("<div");
          manage_link_attributes(&buffer[c],&out);
          out.printE(">\n");
        }
        if(tableMax){
          out.printE("<table style='width:100%;'>\n");
        } else {
          out.printE("<table>\n");
        }
        const char* mA[3]; int mL[3];
        if(string_regexp(rows[end_MTS].v(),0,-1,"^\\s*(Table)?:\\s*(.*)",mA,mL,3)){
          out.printE("<caption>");
          if(id.num() && numbering==1){
            static const char* tableName=NULL;
            if(!tableName){
              MyTSchar* lang=metadata_.getH("lang");
              const char* tableN[]={"en","Table","es","Tabla","ca","Taula",NULL};
              MyhashvecC<char> tableNC(tableN);
              if(lang){
                tableName=tableNC.get(lang->v());
              }
              if(!tableName){
                tableName=tableNC.get("en");
              }
            }
            MKid* mkid=idsG_.getH(id.v());
            if(mkid && mkid->number_.num()){
              out.printE("<strong>%s %s</strong>. ",tableName,mkid->number_.v());
            }
          }
          int c0=mA[2]-rows[end_MTS].v();
          int cend=c0+mL[2]-1;
          this->output_paragraph(rows[end_MTS],out,c0,cend,iblock);
          out.printE("</caption>");
          rows.decr_num();
          if(rows[end_MTS].regexp(0,"^\\s*$")) rows.decr_num();
        }
        if(weightTot>0){
          out.printE("<colgroup>\n");
          for(int i=0;i<weights.num();i++){
            out.printE("<col style='width: %d%%;'/>\n",100*weights[i]/weightTot);
          }
          out.printE("</colgroup>\n");
        }
        out.printE("<thead>\n<tr class='header'>\n");
        string_split(rows[0].v(),"\\s*\\|\\s*",cols);
        for(int i=0;i<cols.num();i++){
          if((i==0 || i==cols.num()-1) && cols[i].regexp(0,"^\\s*$")){
            cols.clear(i); i--; continue;
          }
          if(i>=align.num() || align[i].num()==0){
            out.printE("<th>");
          } else {
            out.printE("<th style='text-align: %s;'>",align[i].v());
          }
          this->output_paragraph(cols[i],out,0,cols[i].num()-1,iblock);
          out.printE("</th>");
        }
        out.printE("</tr>\n</thead>\n<tbody>\n");
        for(int irow=2;irow<rows.num();irow++){
          out.printE("<tr>\n");
          string_split(rows[irow].v(),"\\s*\\|\\s*",cols);
          for(int i=0;i<num_columns;i++){
            if((i==0 || i==cols.num()-1) && cols[i].regexp(0,"^\\s*$")){
              cols.clear(i); i--; continue;
            }
            if(i>=align.num() || align[i].num()==0){
              out.printE("<td>");
            } else {
              out.printE("<td style='text-align: %s;'>",align[i].v());
            }
            if(i<cols.num()){
              this->output_paragraph(cols[i],out,0,cols[i].num()-1,iblock);
            }
            out.printE("</td>");
          }
          out.printE("</tr>\n");
        }
        if(fileName.num()){
          this->fill_table_from_file(fileName.v(),align,out);
        }
        out.printE("</tbody>\n</table>\n");
        if(has_attributes){
          out.printE("</div>\n");
        }
      }
    }
    break;
    case MK::paragraph: case MK::implicit_figures:
    {
      int tight=0,has_attributes=0,formula=0,reference=0,needs_p=1;
      MKid* mkid=NULL;
      MyTSchar id;
      if(blocks_[blocks_[iblock].parent_].mtype_==MK::list_item){
        tight=blocks_[blocks_[iblock].parent_].tight_;
      }
      if(!tight){
        if(otype_==OT::html){
          force_line_start(out);
          if(this->is_extension_active(EXT::link_attributes)){
            int c0=blocks_[iblock].posNoBlank_[0];
            int c1=blocks_[iblock].posNoBlank_[1];
            has_attributes=manage_link_attributes(&buffer[c1+1],NULL,&id);
            if(has_attributes){
              out.printE("<div");
              const char* mA[2]; int mL[2];
              const char* add_class=NULL;
              if(string_regexp(buffer.v(),c0,c1+1,"\\A\\s*[$]{1,2}.*[$]{1,2}\\s*\\Z")){
                if(id.num()){
                  mkid=idsG_.getH(id.v());
                  if(mkid && mkid->number_.num()){
                    formula=1;
                    add_class="MDformula";
                    needs_p=0;
                  }
                }
              } else if(string_regexp(buffer.v(),c0,c1+1,"\\A\\s*\\[(\\d+)\\]",mA,mL,2)){
                add_class="MDreference";
              }
              manage_link_attributes(&buffer[c1+1],&out,NULL,NULL,NULL,NULL,NULL,add_class);
              out.printE(">\n");
              if(formula && mkid && mkid->number_.num()){
                out.printE("<table>\n<tbody>\n<tr>\n<td style='text-align: center;'>");
              }
            }
          }
          if(needs_p){
            out.printE("<p>");
          }
        }
      }
      if(otype_==OT::html){
        this->output_paragraph(buffer,out,iblock);
      }
      if(!tight){
        if(otype_==OT::html){
          if(has_attributes){
            if(formula && mkid && mkid->number_.num()){
              out.printE("</td>\n<td style='text-align: right;'>");
              out.printE("(%s)",mkid->number_.v());
              out.printE("</td>\n</tr>\n</tbody>\n</table>");
            }
            out.printE("</div>\n");
          }
          if(needs_p){
            out.printE("</p>\n");
          }
        }
      }
    }
    break;
    default:
    {
//       if(otype_==OT::html){
//         out.printE("<p>");
//         this->output_paragraph(buffer,out,iblock);
//         out.printE("</p>\n");
//       }
    }
    break;
  }
  
  for(int i=0;i<blocks_[iblock].children_.num();i++){
    this->output_markdown(buffer,out,blocks_[iblock].children_[i]);
  }
  switch(blocks_[iblock].mtype_){
    case MK::list_item:
    {
      if(otype_==OT::html){
        out.printE("</li>\n");
      }
      int iblock_next=this->give_next(iblock);
      if(iblock_next==-1 || blocks_[iblock_next].mtype_!=MK::list_item){
        if(otype_==OT::html){
          if(buffer.regexp(blocks_[iblock].pos_[0],"^\\s*\\d{1,9}[.\\)]")){
            out.printE("</ol>\n");
          } else {
            out.printE("</ul>\n");
          }
        }
      }
    }
    break;
    case MK::block_quote:
    {
      if(otype_==OT::html){
        out.printE("</blockquote>\n");
      }
    }
    break;
  }
}

//################################################################################
//    svgml
//################################################################################

Mytextlongtable* Svgml::propNames_=NULL;
Mytextlongtable* Svgml::cmdNames_=NULL;

static void computeArc(vec2 x0,vec2 r,float angle,int largeArcFlag,int sweepFlag,vec2 x,
  vec2& center,float& angleStart,float& angleExtent)
{
// http://svn.apache.org/repos/asf/xmlgraphics/batik/branches/svg11/sources/org/apache/batik/ext/awt/geom/ExtendedGeneralPath.java
//
// Elliptical arc implementation based on the SVG specification notes
//
  
// Compute the half distance between the current and the final point
  vec2 dx2=0.5f*(x0-x);
  float cosAngle=cos(angle);
  float sinAngle=sin(angle);
  
//
// Step 1 : Compute (x1, y1)
//
  vec2 x1(cosAngle*dx2[0]+sinAngle*dx2[1],-sinAngle*dx2[0]+cosAngle*dx2[1]);

// Ensure radii are large enough
  r[0]=fabs(r[0]);
  r[1]=fabs(r[1]);

  float Prx=r[0]*r[0];
  float Pry=r[1]*r[1];
  float Px1=x1[0]*x1[0];
  float Py1=x1[1]*x1[1];
  
// check that radii are large enough
  float radiiCheck = Px1/Prx + Py1/Pry;
  if(radiiCheck>1){
    r[0] = sqrt(radiiCheck) * r[0];
    r[1] = sqrt(radiiCheck) * r[1];
    Prx=r[0]*r[0];
    Pry=r[1]*r[1];
  }

//
// Step 2 : Compute (cx1, cy1)
//
  float sign = (largeArcFlag == sweepFlag) ? -1 : 1;
  float sq = ((Prx*Pry)-(Prx*Py1)-(Pry*Px1)) / ((Prx*Py1)+(Pry*Px1));
  sq = (sq < 0) ? 0 : sq;
  float coef = (sign * sqrt(sq));
  float cx1 = coef * ((r[0] * x1[1]) / r[1]);
  float cy1 = coef * -((r[1] * x1[0]) / r[0]);
  
//
// Step 3 : Compute (cx, cy) from (cx1, cy1)
//
  float sx2 = (x0[0] + x[0]) / 2.0;
  float sy2 = (x0[1] + x[1]) / 2.0;
  center[0] = sx2 + (cosAngle * cx1 - sinAngle * cy1);
  center[1] = sy2 + (sinAngle * cx1 + cosAngle * cy1);
  
//
// Step 4 : Compute the angleStart (angle1) and the angleExtent (dangle)
//
  float ux = (x1[0] - cx1) / r[0];
  float uy = (x1[1] - cy1) / r[1];
  float vx = (-x1[0] - cx1) / r[0];
  float vy = (-x1[1] - cy1) / r[1];
  float p, n;
// Compute the angle start
  n = sqrt((ux * ux) + (uy * uy));
  p = ux; // (1 * ux) + (0 * uy)
  sign = (uy < 0) ? -1 : 1;
  angleStart = sign * acos(p / n);
  
// Compute the angle extent
  n = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
  p = ux * vx + uy * vy;
  sign = (ux * vy - uy * vx < 0) ? -1 : 1;
  angleExtent = sign * acos(p / n);
  if(!sweepFlag && angleExtent > 0) {
    angleExtent -= float(2*M_PI);
  } else if (sweepFlag && angleExtent < 0) {
    angleExtent += float(2*M_PI);
  }
  angleExtent=fmod(angleExtent,2*M_PI);
  angleStart=fmod(angleStart,2*M_PI);
}

static int next_property(const char* buffer,int& start,int endL,const char* name_valueA[2],
  int name_valueL[2])
{
  const char* mA[3]; int mL[3];
  const char* rex="\\A\\s*(\\+?[a-zA-Z][-\\w]*)\\s*:([^;]*);";
  if(string_regexp(buffer,start,endL,rex,mA,mL,3)==1){
    name_valueA[0]=mA[1]; name_valueL[0]=mL[1];
    name_valueA[1]=mA[2]; name_valueL[1]=mL[2];
    while(name_valueA[1][0]==' '){ name_valueA[1]++; name_valueL[1]--; }
    while(name_valueL[1]>0 && name_valueA[1][name_valueL[1]-1]==' '){ name_valueL[1]--; }
    start=mA[0]-buffer+mL[0];
    return 0;
  }
  return -1;
}

inline dvec3 eval_quadratic_bezier(dvec3 bpnts[],double t)
{
  return (1.0-t)*(1.0-t)*bpnts[0]+2.0*(1.0-t)*t*bpnts[1]+t*t*bpnts[2];
}

inline dvec3 eval_der_quadratic_bezier(dvec3 bpnts[],double t)
{
  return -2.0*(1.0-t)*bpnts[0]+(2.0-4.0*t)*bpnts[1]+2.0*t*bpnts[2];
}

inline dvec3 eval_der2_quadratic_bezier(dvec3 bpnts[],double t)
{
  return 2.0*bpnts[0]-4.0*bpnts[1]+2.0*bpnts[2];
}

// inline dvec3 eval_cubic_bezier(dvec3 bpnts[],double t)
// {
//   double n_over_i=1.0;
//   double s=(1.0-t);
//   double fact=1.0;
//   dvec3 x=s*bpnts[0];
//   for(int i=1;i<3;i++){
//     fact*=t;
//     n_over_i*=(4.0-i)/i;
//     x=s*x+fact*n_over_i*s*bpnts[i];
//   }
//   x+=fact*t*bpnts[3];
//   return x;
// }

inline dvec3 eval_cubic_bezier(dvec3 bpnts[],double t)
{
  return pow(1.0-t,3)*bpnts[0]+3.0*pow(1.0-t,2)*t*bpnts[1]+3.0*(1.0-t)*pow(t,2)*bpnts[2]+
    pow(t,3)*bpnts[3];
}
  
inline dvec3 eval_der_cubic_bezier(dvec3 bpnts[],double t)
{
  return 3.0*pow(1.0-t,2)*(bpnts[1]-bpnts[0])+6*(1.0-t)*t*(bpnts[2]-bpnts[1])+
    3.0*pow(t,2)*(bpnts[3]-bpnts[2]);
}

inline dvec3 eval_der2_cubic_bezier(dvec3 bpnts[],double t)
{
  return 6.0*(1.0-t)*(bpnts[2]-2.0*bpnts[1]+bpnts[0])+6.0*t*(bpnts[3]-2.0*bpnts[2]+bpnts[1]);
}

inline dvec3 eval_bezier(SvgmlPoints s,dvec3 bpnts[],double t)
{
  if(is_cubic(s)){ 
    return eval_cubic_bezier(bpnts,t); 
  } else { 
    return eval_quadratic_bezier(bpnts,t); 
  }
}

inline dvec3 eval_der_bezier(SvgmlPoints s,dvec3 bpnts[],double t)
{
  if(is_cubic(s)){ 
    return eval_der_cubic_bezier(bpnts,t); 
  } else { 
    return eval_der_quadratic_bezier(bpnts,t); 
  }
}

inline dvec3 eval_der2_bezier(SvgmlPoints s,dvec3 bpnts[],double t)
{
  if(is_cubic(s)){ 
    return eval_der2_cubic_bezier(bpnts,t); 
  } else { 
    return eval_der2_quadratic_bezier(bpnts,t); 
  }
}

inline dvec3 eval_2D_arc(const glm::mat2& mat_rot,vec2 r,double angleStart,double angleExtent,
  vec2 center,double t)
{
  double angleMid=angleStart+t*angleExtent;
  vec2 mid=mat_rot*vec2(r[0]*cos(angleMid),r[1]*sin(angleMid))+center;
  return dvec3(mid[0],mid[1],0.0);
}

inline dvec3 eval_der_2D_arc(const glm::mat2& mat_rot,vec2 r,double angleStart,double angleExtent,
  vec2 center,double t)
{
  double angleMid=angleStart+t*angleExtent;
  vec2 mid=mat_rot*vec2(-r[0]*angleExtent*sin(angleMid),r[1]*angleExtent*cos(angleMid));
  return dvec3(mid[0],mid[1],0.0);
}

inline dvec3 eval_der2_2D_arc(const glm::mat2& mat_rot,vec2 r,double angleStart,double angleExtent,
  vec2 center,double t)
{
  double angleMid=angleStart+t*angleExtent;
  vec2 mid=mat_rot*vec2(-r[0]*pow(angleExtent,2)*cos(angleMid),-r[1]*pow(angleExtent,2)*sin(angleMid));
  return dvec3(mid[0],mid[1],0.0);
}

inline SvgmlPoints to_absolute(SvgmlPoints s)
{
  switch(s){
    case TP::dp: return TP::p;
    case TP::l: return TP::L;
    case TP::h: return TP::H;
    case TP::v: return TP::V;
    case TP::i: return TP::L;
    case TP::a: return TP::A;
    case TP::m: return TP::M;
    case TP::c: return TP::CC;
    case TP::q: return TP::Q;
    case TP::z: return TP::Z;
  }
  return s;
}

inline dvec3 tangent_normal_to_bezier(SvgmlPoints s,SvgmlTangentNormal tangent_normal,
  dvec3 bpnts[],dvec3 point0)
{
  double t,d,der_d,min_t,min_d; int is_init=0;
  for(t=0.0;t<=1.0;t+=0.1){
    dvec3 v=eval_bezier(s,bpnts,t);
    dvec3 vp0=v-point0;
    dvec3 der_v=eval_der_bezier(s,bpnts,t);
    if(tangent_normal==TN::tangent){
      d=dot(der_v,vp0)+(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
    } else if(tangent_normal==TN::tangent_alt){
      d=dot(der_v,vp0)-(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
    } else {
      d=dot(der_v,vp0);
    }
    if(!is_init || fabs(d)<fabs(min_d)){
      min_t=t;
      min_d=d;
      is_init=1; 
    }
  }
  t=min_t;
  for(int iter=0;iter<10;iter++){
    dvec3 v=eval_bezier(s,bpnts,t);
    dvec3 vp0=v-point0;
    dvec3 der_v=eval_der_bezier(s,bpnts,t);
    dvec3 der2_v=eval_der2_bezier(s,bpnts,t);
    if(tangent_normal==TN::tangent){
      d=dot(der_v,vp0)+(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
      der_d=dot(der2_v,vp0)+dot(der_v,der_v)+
        dot(der_v,der2_v)/sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0))+
        sqrt(dot(der_v,der_v))*(dot(v,der_v)-dot(der_v,point0))/sqrt(dot(vp0,vp0));
    } else if(tangent_normal==TN::tangent_alt){
      d=dot(der_v,vp0)-(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
      der_d=dot(der2_v,vp0)+dot(der_v,der_v)-
        dot(der_v,der2_v)/sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0))-
        sqrt(dot(der_v,der_v))*(dot(v,der_v)-dot(der_v,point0))/sqrt(dot(vp0,vp0));
    } else {
      d=dot(der_v,vp0);
      der_d=dot(der2_v,vp0)+dot(der_v,der_v);
    }
    t-=d/der_d;
    if(t<0.0){ t=0.0; break; }
    if(t>1.0){ t=1.0; break; }
  }
  return eval_bezier(s,bpnts,t);
}

inline dvec3 tangent_normal_to_arc(SvgmlTangentNormal tangent_normal,
  const glm::mat2& mat_rot,vec2 r,double angleStart,double angleExtent,
  vec2 center,dvec3 point0)
{
  double t,d,der_d,min_t,min_d; int is_init=0;
  for(t=0.0;t<=1.0;t+=0.1){
    dvec3 v=eval_2D_arc(mat_rot,r,angleStart,angleExtent,center,t);
    dvec3 vp0=v-point0;
    dvec3 der_v=eval_der_2D_arc(mat_rot,r,angleStart,angleExtent,center,t);
    if(tangent_normal==TN::tangent){
      d=dot(der_v,vp0)+(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
    } else if(tangent_normal==TN::tangent_alt){
      d=dot(der_v,vp0)-(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
    } else {
      d=dot(der_v,vp0);
    }
    if(!is_init || fabs(d)<fabs(min_d)){
      min_t=t;
      min_d=d;
      is_init=1; 
    }
  }
  t=min_t;
  for(int iter=0;iter<10;iter++){
    dvec3 v=eval_2D_arc(mat_rot,r,angleStart,angleExtent,center,t);
    dvec3 vp0=v-point0;
    dvec3 der_v=eval_der_2D_arc(mat_rot,r,angleStart,angleExtent,center,t);
    dvec3 der2_v=eval_der2_2D_arc(mat_rot,r,angleStart,angleExtent,center,t);
    if(tangent_normal==TN::tangent){
      d=dot(der_v,vp0)+(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
      der_d=dot(der2_v,vp0)+dot(der_v,der_v)+
        dot(der_v,der2_v)/sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0))+
        sqrt(dot(der_v,der_v))*(dot(v,der_v)-dot(der_v,point0))/sqrt(dot(vp0,vp0));
    } else if(tangent_normal==TN::tangent_alt){
      d=dot(der_v,vp0)-(sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0)));
      der_d=dot(der2_v,vp0)+dot(der_v,der_v)-
        dot(der_v,der2_v)/sqrt(dot(der_v,der_v))*sqrt(dot(vp0,vp0))-
        sqrt(dot(der_v,der_v))*(dot(v,der_v)-dot(der_v,point0))/sqrt(dot(vp0,vp0));
    } else {
      d=dot(der_v,vp0);
      der_d=dot(der2_v,vp0)+dot(der_v,der_v);
    }
    t-=d/der_d;
    if(t<0.0){ t=0.0; break; }
    if(t>1.0){ t=1.0; break; }
  }
  return eval_2D_arc(mat_rot,r,angleStart,angleExtent,center,t);
}

void SvgmlEntity::set_id(const char* id,size_t len)
{
  id_.setV(id,len);
}

void SvgmlEntity::set(const char* id,size_t len,SvgmlCommands cmd,
  const char* contents,size_t clen,const char* line,size_t llen)
{
  const char* name_valueA[2]; int name_valueL[2];
  MyTSchar name;
  MyTScharList list;
  
  cmd_=cmd;
  id_.setV(id,len);
  string_split_text_sep(id_.v(),id_.num(),".",list);
  id_short_=list[end_MTS];
  list.decr_num();
  string_join(list,".",id_parent_);
  if(id_parent_.num()==0) id_parent_.setV("0",-1);
  
  contents_.setV(contents,clen);
  if(line){
    line_.setV(line,llen);
  }
  int c=0;
  while(next_property(contents_.v(),c,-1,name_valueA,name_valueL)!=-1){
    name.setV(name_valueA[0],name_valueL[0]);
    if(!Svgml::propNames_->exists(name.v())){
      if(cmd==OC::cclass){
        continue;
      }
      throw MyTSchar("Property '%s' does not exist in line '%s'",name.v(),line_.v());
    }
    int is_append=0;
    if(name[0]=='+'){
      is_append=1;
      name.clear(0);
    }
    SvgmlProperties prop=SvgmlProperties(Svgml::propNames_->get(name.v()));
    if(properties_.exists(ggclong(prop))){
      if(is_append){
        properties_.getF_L(ggclong(prop)).value_.appendV(name_valueA[1],name_valueL[1]);
      } else {
        properties_.incr_num().value_.setV(name_valueA[1],name_valueL[1]);
        properties_[end_MTS].name_=prop;
        properties_.set(ggclong(prop),properties_.num()-1);
      }
    } else {
      properties_.appendL(ggclong(prop)).name_=prop;
      properties_[end_MTS].value_.setV(name_valueA[1],name_valueL[1]);
    }
    properties_[end_MTS].value_.regsub(0,"(?i)\\\\0{0,4}3B ?",";");
  }
  if(string_regexp(contents_.v(),c,-1,"\\A\\s*$")==0){
    throw MyTSchar("invalid content '%s' in line '%s'",&contents_[c],line_.v());
  }
}

void SvgmlEntity::update_contents_from_properties()
{
  const char* name_valueA[2]; int name_valueL[2];
  MyTSchar name,value;
  MyTSchar contents;
  int c=0;
  while(next_property(contents_.v(),c,-1,name_valueA,name_valueL)!=-1){
    name.setV(name_valueA[0],name_valueL[0]);
    value.setV(name_valueA[1],name_valueL[1]);
    if(Svgml::propNames_->exists(name.v())){
      SvgmlProperties prop=SvgmlProperties(Svgml::propNames_->get(name.v()));
      if(properties_.exists(ggclong(prop))){
        value=properties_.getF_L(ggclong(prop)).value_;
      }
    }
    contents.printE("%s:%s;",name.v(),value.v());
  }
  contents_=contents;
}

const int point_to_axes_g_[8][3]={{0,0,0},{1,0,0},{1,1,0},{0,1,0},{0,0,1},{1,0,1},{1,1,1},{0,1,1}};
const int face_to_points_g_[6][4]={{0,1,2,3},{0,4,5,1},{1,2,6,5},{3,7,6,2},{0,3,7,4},{4,5,6,7}};
const int ariste_to_point_g_[12][2]={{0,1},{1,2},{3,2},{0,3},{0,4},{1,5},{2,6},{3,7},{4,5},{5,6},{7,6},{4,7}};
const int face_to_normal_g_[6]={2,1,0,1,0,2};
const int face_to_normal_prev_next_g_[6]={0,0,1,1,0,1};

void SvgmlEntity::calc_rotation_and_size(dquat& rotation_vector,double& width,double& height,double& cube_height)
{
  double angles[2];
  MyTScharList list;
  MyTSchar mA[2];
  
  MyTSchar* anglesTS=this->give_property(OP::angles);
  if(anglesTS){
    string_split(anglesTS->v(),"\\s*,\\s*",list);
    if(list.num()!=2){
      throw MyTSchar("properties angles must be: angles:45deg,45deg; line='%s'",line_.v());
    }
    for(int i=0;i<2;i++){
      if(list[i].regexp(0,"^\\s*([-+\\d.e]+)\\s*deg\\s*$",mA,2)==1){
        angles[i]=DEGTORAD*atof(mA[1].v());
      } else if(list[i].regexp(0,"^\\s*([-+\\d.e]+)\\s*rad\\s*$",mA,2)==1){
        angles[i]=atof(mA[1].v());
      } else {
        throw MyTSchar("properties angles must be: angles:45deg,45deg; line='%s'",line_.v());
      }
    }
  } else {
    angles[0]=angles[1]=45.0*DEGTORAD;
  }
  double angleXY=angles[0]+90*DEGTORAD;
  double angleZ=-1.0*(angles[1]-90*DEGTORAD);
  dquat a=angleAxis(angleXY,dvec3(0,0,1));
  dquat newaxis=angleAxis(angleZ,dvec3(1,0,0));
  rotation_vector=normalize(cross(a,newaxis));
  
  width=bbox_[2];
  height=bbox_[3];
  
  SvgmlPoint* whPoint=give_point(TP::width_height);
  if(whPoint){
    cube_height=whPoint->pointG_[2];
  } else {
    cube_height=bbox_[3];
  }
}

void SvgmlEntity::process_cube(SvgmlPointsConnections label,MyTSchar& style,
  MyTSchar& out,Svgml& svgml)
{
  double width,height,cube_height;
  dquat rotation_vector;
  
  this->calc_rotation_and_size(rotation_vector,width,height,cube_height);
  
  dvec3 p0(bbox_[0]+0.5*width,bbox_[1]+0.5*height,0);
  
  if(svgml.otype_==OTS::svg){
    const int faces[]={0,1,4,2,3,5};
    for(int i_face=0;i_face<6;i_face++){
      int idx_face=faces[i_face];
      MyTSchar ds;
      for(int i=0;i<4;i++){
        int idx_point=face_to_points_g_[idx_face][i];
        dvec3 xL(
          (-1+2*point_to_axes_g_[idx_point][0])*0.5*width,
          (-1+2*point_to_axes_g_[idx_point][1])*0.5*height,
          point_to_axes_g_[idx_point][2]*cube_height
          );
        dvec3 v=transpose(toMat3(rotation_vector))*xL;
        v[1]*=-1;
        dvec3 pnt=p0+v;   
        if(ds.num()==0){
          ds.printE("M%.3g,%.3g",pnt[0],pnt[1]);
        } else {
          ds.printE(" L%.3g,%.3g",pnt[0],pnt[1]);
        }
      }
      ds.printE(" z");
      out.printE("<path d='%s' id='%s-%d' style='%s'/>\n",ds.v(),id_.v(),idx_face,style.v());
    }
  }
  if(svgml.otype_!=OTS::svg){
    return; 
  }
  if(label==TPC::face || label==TPC::all){
    for(int idx_face=0;idx_face<6;idx_face++){
      dvec3 center_face;
      for(int i=0;i<4;i++){
        int idx_point=face_to_points_g_[idx_face][i];
        dvec3 xL(
          (-1+2*point_to_axes_g_[idx_point][0])*0.5*width,
          (-1+2*point_to_axes_g_[idx_point][1])*0.5*height,
          point_to_axes_g_[idx_point][2]*cube_height
          );
        dvec3 v=transpose(toMat3(rotation_vector))*xL;
        v[1]*=-1;
        dvec3 pnt=p0+v;   
        center_face+=0.25*pnt;
      }
      out.printE("<text x='%.4g' y='%.3g' style='fill: red;'>%d</text>\n",center_face[0],
        center_face[1],idx_face+1);
    }
  }
  if(label==TPC::ariste || label==TPC::all){
    for(int idx_ariste=0;idx_ariste<12;idx_ariste++){
      dvec3 center_ariste;
      for(int i=0;i<2;i++){
        int idx_point=ariste_to_point_g_[idx_ariste][i];
        dvec3 xL(
          (-1+2*point_to_axes_g_[idx_point][0])*0.5*width,
          (-1+2*point_to_axes_g_[idx_point][1])*0.5*height,
          point_to_axes_g_[idx_point][2]*cube_height
          );
        dvec3 v=transpose(toMat3(rotation_vector))*xL;
        v[1]*=-1;
        dvec3 pnt=p0+v;   
        center_ariste+=0.5*pnt;
      }
      out.printE("<text x='%.4g' y='%.3g' style='fill: blue;'>%d</text>\n",center_ariste[0],
        center_ariste[1],idx_ariste+1);
    }
  }
  if(label==TPC::vertex || label==TPC::all){
    for(int idx_point=0;idx_point<8;idx_point++){
      dvec3 xL(
        (-1+2*point_to_axes_g_[idx_point][0])*0.5*width,
        (-1+2*point_to_axes_g_[idx_point][1])*0.5*height,
        point_to_axes_g_[idx_point][2]*cube_height
        );
      dvec3 v=transpose(toMat3(rotation_vector))*xL;
      v[1]*=-1;
      dvec3 pnt=p0+v;   
      out.printE("<text x='%.4g' y='%.3g' style='fill: blue;'>%d</text>\n",pnt[0],
        pnt[1],idx_point+1);
    }
  }
}

void SvgmlEntity::calculate_connection_point_cube(SvgmlPointsConnections point_conexion,
  int point_conexionN,int ncoords,glm::dvec3& point)
{
  double width,height,cube_height;
  dquat rotation_vector;
  dvec3 face_pnts[4];
  
  this->calc_rotation_and_size(rotation_vector,width,height,cube_height);
  
  dvec3 params=point/100.0;
  dvec3 p0(bbox_[0]+0.5*width,bbox_[1]+0.5*height,0);
  
  if(point_conexion==TPC::face){
    int idx_face=point_conexionN-1;
    for(int i=0;i<4;i++){
      int idx_point=face_to_points_g_[idx_face][i];
      dvec3 xL(
        (-1+2*point_to_axes_g_[idx_point][0])*0.5*width,
        (-1+2*point_to_axes_g_[idx_point][1])*0.5*height,
        point_to_axes_g_[idx_point][2]*cube_height);
      dvec3 v=transpose(toMat3(rotation_vector))*xL;
      v[1]*=-1;
      face_pnts[i]=p0+v;
    }
    dvec3 normal=triangleNormal(face_pnts[0],face_pnts[1],face_pnts[2]);
    double sign=(face_to_normal_prev_next_g_[idx_face]==1)?-1:1;
    normal=sign*width*normalize(normal);
    
    dvec3 dx=params[0]*(face_pnts[1]-face_pnts[0]);
    dvec3 dy=params[1]*(face_pnts[3]-face_pnts[0]);
    dvec3 dz=params[2]*normal;
    point=face_pnts[0]+dx+dy+dz;
  } else if(point_conexion==TPC::vertex){
    int idx_point=point_conexionN-1;
    dvec3 xL(
      (-1+2*point_to_axes_g_[idx_point][0])*0.5*width,
      (-1+2*point_to_axes_g_[idx_point][1])*0.5*height,
      point_to_axes_g_[idx_point][2]*cube_height);
    dvec3 v=transpose(toMat3(rotation_vector))*xL;
    v[1]*=-1;
    point=p0+v;
  } else {
    throw MyTSchar("cube,ariste not implemented yet; line='%s'",line_.v());
  }
}

SvgmlEntity* SvgmlEntity::give_copy_real_id(Svgml& svgml)
{
  MyTSchar* from=this->give_property(OP::from);
  MyTSchar from0;
  if(from){
    MyTScharList idsList;
    string_split_text_sep(from->v(),-1,",",idsList);
    MyTSchar mATS[2];
    idsList[0].regexp(0,"(\\S+)",mATS,2);
    from0=mATS[1];
  } else {
    from0=id_parent_;
  }
  SvgmlEntity* from0_entity=svgml.give_entity(from0.v(),id_.v());

  MyTSchar id("%s.__1__%s",id_.v(),from0_entity->id_.v());
  SvgmlEntity* ret=svgml.give_entity(id.v(),id_.v());
  if(!ret){
    throw MyTSchar("error with '%s'. Reference not valid. line='%s'",
      id.v(),line_.v());
  }
  return ret;
}
  
void SvgmlEntity::calculate_connection_point(SvgmlPointsConnections connectionP,
  int point_conexionN[2],SvgmlTangentNormal tangent_normal,int ncoords,
  MyTSvec<SvgmlPoint,3>& points,Svgml& svgml)
{
  if(!is_calculated_){
    throw MarkdownException(EXP::needs_recalculate);
  }
  
  if(cmd_==OC::copy){
    SvgmlEntity* from0=this->give_copy_real_id(svgml);
    from0->calculate_connection_point(connectionP,point_conexionN,tangent_normal,
      ncoords,points,svgml);
    return;
  }
  if(cmd_==OC::cube){
    points[end_MTS].set_connection(connectionP,point_conexionN[0],id_.v());
    this->calculate_connection_point_cube(connectionP,point_conexionN[0],ncoords,
      points[end_MTS].pointG_);
    points[end_MTS].point_=points[end_MTS].pointG_;
    return;
  }
  if(connectionP==TPC::face){
    throw MyTSchar("face is only allowed for cubes. line='%s'",id_.v(),line_.v());
  }

  dvec3 params=points[end_MTS].pointG_/100.0;

  int idx=1;
  int i=0,delta=1,segment_started=0,num_loops=0;
  while(1){
    if(i==points_.num()){
      if(points_.num()==0 || !is_any_segment(connectionP) || num_loops==1){
        throw MyTSchar("incorrect connection point. line='%s'",id_.v(),line_.v());
      }
      num_loops++;
      i=0;
    } else if(i<0){
      if(num_loops==1){
        throw MyTSchar("incorrect connection point. line='%s'",id_.v(),line_.v());
      }
      num_loops++;
      i=points_.num()-1;
    }
    if(idx<point_conexionN[0] && segment_started==0){
      i++;
      if(!is_point(points_[i-1].ptype_)) continue;
      idx++;
      continue;
    }
    if(connectionP==TPC::vertex){
      if(!is_point(points_[i].ptype_)){
        i++;
        continue;
      }
      points[end_MTS].set_connection(connectionP,point_conexionN[0],id_.v());
      points[end_MTS].point_=points[end_MTS].pointG_=points_[i].pointG_;
      return;
    } else if(is_any_segment(connectionP)){
      if(connectionP==TPC::segment_inverse) delta=-1;
      if(segment_started){
        points.incr_num();
      }
      if(is_point(points_[i].ptype_)){
        if(segment_started && connectionP==TPC::segment && is_arc(points_[i].ptype_)){
          points[end_MTS].ptype_=to_absolute(points_[i].ptype_);
          points[end_MTS].parameters_=points_[i].parameters_;
        } else if(segment_started && connectionP==TPC::segment_inverse && i<points_.num()-1 &&
          is_arc(points_[i+1].ptype_)){
          points[end_MTS].ptype_=to_absolute(points_[i+1].ptype_);
          points[end_MTS].parameters_=points_[i+1].parameters_;
          points[end_MTS].parameters_[4]=(points[end_MTS].parameters_[4])?0:1;
        } else if(segment_started){
          points[end_MTS].ptype_=TP::p;
        }
      } else {
        points[end_MTS].ptype_=to_absolute(points_[i].ptype_);
      }
      segment_started=1;
      points[end_MTS].set_connection(connectionP,idx,id_.v());
      points[end_MTS].point_=points[end_MTS].pointG_=points_[i].pointG_;
      if(idx==point_conexionN[1]){
        return;
      }
      if(is_point(points_[i].ptype_)) idx+=delta;
      i+=delta;
    } else {
      if(!is_point(points_[i].ptype_)){
        i++;
        continue;
      }
      int i_next=i;
      for(int i_try=0;i_try<3;i_try++){
        if(i_next<points_.num()-1) i_next++;
        else i_next=0;
        if(!is_zZ(points_[i_next].ptype_)) break;
      }
      dvec3 point;
      if(is_qc(points_[i_next].ptype_)){
        dvec3 bpnts[4];
        bpnts[0]=points_[i].pointG_;
        bpnts[1]=points_[i_next].pointG_;
        if(is_cubic(points_[i_next].ptype_) && i_next>=points_.num()-2){
          throw MyTSchar("cubic is not ok. line='%s'",line_.v());
        }
        if(i_next>=points_.num()-1){
          throw MyTSchar("quadratic is not ok. line='%s'",line_.v());
        }
        bpnts[2]=points_[i_next+1].pointG_;
        if(is_cubic(points_[i_next].ptype_)){
          bpnts[3]=points_[i_next+2].pointG_;
        }
        double t=params[0];
        if(tangent_normal!=TN::none){
          point=tangent_normal_to_bezier(points_[i_next].ptype_,tangent_normal,
            bpnts,points[end_MTS].pointG_);
        } else {
          point=eval_bezier(points_[i_next].ptype_,bpnts,t);
        }
      } else if(is_arc(points_[i_next].ptype_)){
        vec2 r;
        r[0]=points_[i_next].parameters_[0];
        r[1]=points_[i_next].parameters_[1];
        float phi=fmod(DEGTORAD*points_[i_next].parameters_[2],2*M_PI);
        float cos_phi=cos(phi);
        float sin_phi=sin(phi);
        int largeArcFlag=int(points_[i_next].parameters_[3]);
        int sweepFlag=int(points_[i_next].parameters_[4]);
        
        mat2 mat_rot;
        mat_rot[0]=vec2(cos_phi,-sin_phi);
        mat_rot[1]=vec2(sin_phi,cos_phi);
        
        vec2 c0,c1,center;
        float angleStart,angleExtent;
        c0=vec2(points_[i].pointG_[0],points_[i].pointG_[1]);
        c1=vec2(points_[i_next].pointG_[0],points_[i_next].pointG_[1]);
        computeArc(c0,r,phi,largeArcFlag,sweepFlag,c1,center,angleStart,angleExtent);
        double t=params[0];
        if(tangent_normal!=TN::none){
          point=tangent_normal_to_arc(tangent_normal,mat_rot,r,angleStart,angleExtent,
            center,points[end_MTS].pointG_);
        } else {
          point=eval_2D_arc(mat_rot,r,angleStart,angleExtent,center,t);
        }
      } else if(tangent_normal!=TN::none){
        if(tangent_normal==TN::tangent || tangent_normal==TN::tangent_alt){
          throw MyTSchar("not valid ariste,n,tangent for straight lines. line='%s'",id_.v(),line_.v());
        }
        point=points[end_MTS].pointG_;
        dvec3 v=points_[i].pointG_-point;
        dvec3 t=points_[i_next].pointG_-points_[i].pointG_;
        dvec3 Nplane=cross(v,t);
        dvec3 N_in_plane=normalize(cross(t,Nplane));
        point+=dot(v,N_in_plane)*N_in_plane;
      } else {
        point=(1.0-params[0])*points_[i].pointG_+params[0]*points_[i_next].pointG_;
      }
      if(ncoords==2){
        dvec3 t=points_[i_next].pointG_-points_[i].pointG_;
        dvec3 N_in_plane(-1.0*t[1],t[0],0.0);
        point+=params[1]*N_in_plane;
      }
      points[end_MTS].set_connection(connectionP,point_conexionN[0],id_.v());
      points[end_MTS].point_=points[end_MTS].pointG_=point;
      return;
    }
  }
}

void SvgmlEntity::transform(SvgmlPoint& point,SvgmlEntity* id_parentList[3])
{
  if(is_absolute(point.ptype_)){
    for(int i=0;i<2;i++){
      if(!id_parentList[i]->is_calculated_){
        throw MarkdownException(EXP::needs_recalculate);
      }
      point.point_[i]=id_parentList[i]->bbox_[i]+point.point_[i]/100.0*id_parentList[i]->bbox_[i+2];
    }
  } else {
    for(int i=0;i<2;i++){
      if(!id_parentList[i]->is_calculated_){
        points_.clear();
        throw MarkdownException(EXP::needs_recalculate);
      }
      point.point_[i]=point.point_[i]/100.0*id_parentList[i]->bbox_[i+2];
    }
  }
}

void SvgmlEntity::copy_operation(Svgml& svgml,Svgml_copy& copy_info)
{
  dvec3 delta;
  
  MyTSvec<SvgmlPoint,3> points_prev=points_;
  for(int ipoint=0;ipoint<points_.num();ipoint++){
    if(is_zZ(points_[ipoint].ptype_)) continue;
    for(int i=0;i<copy_info.operations_.num();i++){
      Svgml_copy_OP& op=copy_info.operations_[i];
      if(op.operation_==CO::symmetry){
        double dot=glm::dot(points_[ipoint].pointG_-op.deltaList_[0].point_,
          op.deltaList_[0].delta_);
        points_[ipoint].pointG_-=2.0*dot*op.deltaList_[0].delta_;
        points_[ipoint].point_=points_[ipoint].pointG_;
        points_[ipoint].ptype_=to_absolute(points_[ipoint].ptype_);
        if(points_[ipoint].connectionP_!=TPC::none){
          if(strcmp(points_[ipoint].connection_entity_.v(),
            svgml.entities_[copy_info.entity_from_].id_.v())==0){
            points_[ipoint].connection_entity_=id_;
          } else {
            points_[ipoint].connectionP_=TPC::none;
          }
        }
        points_[ipoint].gid_numbers_=ivec2();
        if(is_arc(points_[ipoint].ptype_)){
          double v=points_[ipoint].parameters_[4];
          points_[ipoint].parameters_[4]=(v==0)?1:0;
        }
      } else {
        if(op.deltaList_.num()){
          double dist_max=0.0;
          for(int j=0;j<op.deltaList_.num();j++){
            double d=distance(points_[ipoint].pointG_,op.deltaList_[j].point_);
            if(d>dist_max){
              dist_max=d;
            }
          }
          delta=dvec3();
          double fac_tot=0.0;
          for(int j=0;j<op.deltaList_.num();j++){
            double d=distance(points_[ipoint].pointG_,op.deltaList_[j].point_);
            double fac=pow(dist_max-d,3);
            delta+=fac*op.deltaList_[j].delta_;
            fac_tot+=fac;
          }
          if(fac_tot!=0.0){
            delta/=fac_tot;
          }
        } else {
          delta=op.delta_;
        }
        if(is_absolute(points_[ipoint].ptype_)){
          points_[ipoint].point_+=delta;
        }
        points_[ipoint].pointG_+=delta;
        if(strcmp(points_[ipoint].connection_entity_.v(),
          svgml.entities_[copy_info.entity_from_].id_.v())==0){
          points_[ipoint].connection_entity_=id_;
        } else {
          points_[ipoint].connectionP_=TPC::none;
        }
        points_[ipoint].gid_numbers_=ivec2();
      }
    }
  }
  MyTSchar contents;
  if(strcmp(copy_info.connect_.v(),"points")==0){
    for(int ipoint=0;ipoint<points_.num();ipoint++){
      if(!is_point(points_[ipoint].ptype_)) continue;
      contents.print0("point:#__ROOT,%.3g,%.3g,%.3g,#__ROOT,%.3g,%.3g,%.3g;",
        points_prev[ipoint].pointG_[0],points_prev[ipoint].pointG_[1],points_prev[ipoint].pointG_[2],
        points_[ipoint].pointG_[0],points_[ipoint].pointG_[1],points_[ipoint].pointG_[2]);
      if(copy_info.connect_class_.num()){
        contents.printE(" class:%s;",copy_info.connect_class_.v());
      }
      MyTSchar id("%s.__CT__%d",svgml.entities_[copy_info.entity_].id_.v(),ipoint);
      if(svgml.entities_.num()==svgml.entities_.give_memnum()){
        svgml.entities_.set_min_memnum(svgml.entities_.num()*2);
        throw MarkdownException(EXP::try_again);
      }
      svgml.entities_.incr_num().set(id.v(),id.num(),OC::line,contents.v(),contents.num(),NULL,-1);
    }
  } else if(strcmp(copy_info.connect_.v(),"lines")==0){
    int npoints=0,is_closed=0;
    for(int ipoint=0;ipoint<points_.num();ipoint++){
      if(!is_point(points_[ipoint].ptype_) && !is_zZ(points_[ipoint].ptype_)) continue;
      if(is_zZ(points_[ipoint].ptype_)) is_closed=1;
      npoints++;
    }
    MyTSchar id_prev;
    for(int i=2;i<=npoints;i++){
      int p_prev=i-1;
      int p=(is_closed && i==npoints)?1:i;
      contents.print0("point:#%s,segment,%d,%d",
        svgml.entities_[copy_info.entity_from_].id_.v(),p_prev,p);
      contents.printE(",#%s,segment_inverse,%d,%d",id_.v(),p,p_prev);
      if(id_prev.num()){
        contents.printE(",#%s,segment_inverse,%d,%d",id_prev.v(),3,2);
      }
      contents.printE(",Z;");
      if(copy_info.connect_class_.num()){
        contents.printE(" class:%s;",copy_info.connect_class_.v());
      }
      MyTSchar id("%s.__CT__%d",svgml.entities_[copy_info.entity_].id_.v(),i);
      if(svgml.entities_.num()==svgml.entities_.give_memnum()){
        svgml.entities_.set_min_memnum(svgml.entities_.num()*2);
        throw MarkdownException(EXP::try_again);
      }
      MyTSchar line("%s %s %s",id.v(),"line",contents.v());
      svgml.entities_.incr_num().set(id.v(),id.num(),OC::line,contents.v(),
        contents.num(),line.v(),line.num());
      id_prev=id;
    }
  }
}

static int is_number(const char* c,double* number=NULL)
{
  char* endptr;
  double d=strtod(c,&endptr);
  if(string_regexp(endptr,0,-1,"^\\s*$")==0) return 0;
  if(number) *number=d;
  return 1;
}

double Svgml::evaluate_expression(const char* v,const char* line)
{
  double d;
  const char* mA[2]; int mL[2];
  MyTSchar rex;
  
  const char* number="([-+]?[.\\de]*\\d)";
  const char* var="(:[-\\w]+)";
  const char* parents="[()]";
  const char* opts="[-+*/]";
  
  rex.print0("\\A\\s*(%s|%s|%s|%s)",parents,number,var,opts);
  MyTScharList stack;
  int c=0;
  while(string_regexp(v,c,-1,rex.v(),mA,mL,2)==1){
    stack.incr_num().setV(mA[1],mL[1]);
    int is_number=0;
    if(stack[end_MTS].regexp(0,var)){
      const char* value=variables_.get(&stack[end_MTS][1]);
      if(!value){
        throw MyTSchar("variable does not exist '%s'. line='%s'",&stack[end_MTS][1],line);
      }
      stack[end_MTS]=value;
      is_number=1;
    } else if(stack[end_MTS].regexp(0,number)){
      is_number=1;
    }
    if(is_number==1 && stack.num()>1 && stack[end_MTS-1].regexp(0,number)){
      stack.insert(end_MTS)="+";
    }
    c=mA[0]-v+mL[0];
  }
  for(int i_try=0;i_try<100;i_try++){
    int num_op=0;
    for(int i=1;i<stack.num()-1;i++){
      if(stack[i].regexp(0,"^[*/]$")==0) continue;
      if(!stack[i-1].regexp(0,number) || !stack[i+1].regexp(0,number)) continue;
      if(stack[i][0]=='*'){
        d=atof(stack[i-1].v())*atof(stack[i+1].v());
      } else {
        d=atof(stack[i-1].v())/atof(stack[i+1].v());
      }
      stack[i-1].print(0,"%g",d);
      stack.clear(i); stack.clear(i);
      i--;
      num_op++;
    }
    for(int i=1;i<stack.num()-1;i++){
      if(stack[i].regexp(0,"^[-+]$")==0) continue;
      if(!stack[i-1].regexp(0,number) || !stack[i+1].regexp(0,number)) continue;
      if(stack[i][0]=='+'){
        d=atof(stack[i-1].v())+atof(stack[i+1].v());
      } else {
        d=atof(stack[i-1].v())-atof(stack[i+1].v());
      }
      stack[i-1].print(0,"%g",d);
      stack.clear(i); stack.clear(i);
      i--;
      num_op++;
    }
    for(int i=0;i<stack.num()-1;i++){
      if(stack[i].regexp(0,"^[-+]$")==0) continue;
      if(i>0 && stack[i-1][0]!='(') continue;
      if(!stack[i+1].regexp(0,number)) continue;
      if(stack[i][0]=='+'){
        d=atof(stack[i+1].v());
      } else {
        d=-1.0*atof(stack[i+1].v());
      }
      stack[i].print(0,"%g",d);
      stack.clear(i+1);
      num_op++;
    }
    for(int i=1;i<stack.num()-1;i++){
      if(stack[i].regexp(0,number)==0) continue;
      if(stack[i-1][0]!='(' || stack[i+1][0]!=')') continue;
      stack[i-1]=stack[i];
      stack.clear(i); stack.clear(i);
      i--;
      num_op++;
    }
    if(num_op==0) break;
  }
  if(stack.num()!=1){
    throw MyTSchar("expression not valid '%s'. line='%s'",v,line);
  }
  return atof(stack[0].v());
  
//   rex.print0("\\A\\s*(?:%s|%s\\s*\\*\\s*(?:%s\\s*\\*\\s*)?%s|([-+]?)%s)",number,number,var,var,var);
//   while(string_regexp(v,c,-1,rex.v(),mA,mL,7)==1){
//     double fac=1.0,delta_d;
//     if(mL[1]>0) d+=atof(mA[1]);
//     if(mL[2]>0) fac=atof(mA[2]);
//     if(mL[3]>0 || mL[4]>0 || mL[6]>0){
//       MyTSchar n;
//       if(mL[4]>0) n.setV(mA[4],mL[4]);
//       else n.setV(mA[6],mL[6]);
//       const char* value=variables_.get(n.v());
//       if(!value){
//         throw MyTSchar("variable does not exist '%s'. line='%s'",n.v(),line);
//       }
//       if(mL[5]>0 && mA[5][0]=='-') fac*=-1;
//       delta_d=fac*atof(value);
//       if(mL[3]>0){
//         n.setV(mA[3],mL[3]);
//         const char* value=variables_.get(n.v());
//         if(!value){
//           throw MyTSchar("variable does not exist '%s'. line='%s'",n.v(),line);
//         }
//         delta_d*=atof(value);
//       }
//       d+=delta_d;
//     }
//     c=mA[0]-v+mL[0];
//   }
//   if(string_regexp(v,c,-1,"\\A\\s*$")==0){
//     throw MyTSchar("expression not valid '%s'. line='%s'",v,line);
//   }
//   return d;
}

void SvgmlEntity::calculate_points(Svgml& svgml,Svgml_copy* copy_info)
{
  SvgmlPoints ptype;
  MyTSchar mAT[2];
  MyTScharList list;
  char* endptr;
  SvgmlEntity* id_parent,*id_parentList[3];
  
  if(cmd_==OC::cclass) return;
  id_parent=svgml.give_entity(id_parent_.v(),id_.v());
  if(!id_parent){
    throw MyTSchar("Entity '%s' does not have a valid parent. line='%s'",
      id_.v(),line_.v());
  }
  
  points_.clear();
  
  for(int i=0;i<properties_.num();i++){
    if(!is_point_stype(properties_[i].name_)) continue;
    //puts "---calculate_points $n --- $v"
    switch(properties_[i].name_){
      case OP::point: ptype=TP::p; break;
      case OP::delta_point: ptype=TP::dp; break;
      case OP::width_height: ptype=TP::width_height; break;
    }
    id_parentList[0]=id_parentList[1]=id_parentList[2]=id_parent;
    string_split(properties_[i].value_.v(),"\\s*,\\s*",list);
    dvec3 point; int icoord=0; MyTSvec<double,5> parameters;
    SvgmlTangentNormal tangent_normal=TN::none;
    SvgmlPointsConnections connectionP=TPC::none; int connectionN[2];
    for(int j=0;j<list.num();j++){
      point[icoord]=strtod(list[j].v(),&endptr);
      if(*endptr=='\0'){
        icoord++;
      } else if(list[j].regexp(0,":")){
        point[icoord]=svgml.evaluate_expression(list[j].v(),line_.v());
        icoord++;
      } else if(list[j].regexp(0,"^#(\\S+)$",mAT,2)){
        id_parentList[icoord]=svgml.give_entity(mAT[1].v(),id_.v());
        if(!id_parentList[icoord]){
          throw MyTSchar("error with '%s'. Reference not valid. line='%s'",
            mAT[1].v(),line_.v());
        }
        for(int k=icoord+1;k<3;k++){
          id_parentList[k]=id_parentList[icoord];
        }
        continue;
      } else if(list[j].regexp(0,"^(tangent|tangent_alt|normal)$",mAT,1)){
        if(connectionP!=TPC::ariste){
          throw MyTSchar("tangent and normal only implemented in ariste,n,"
            "tangent|normal '%s' not valid. line='%s'",
            properties_[i].value_.v(),line_.v());
        }
        if(strcmp(mAT[0].v(),"tangent")==0) tangent_normal=TN::tangent;
        else if(strcmp(mAT[0].v(),"tangent_alt")==0) tangent_normal=TN::tangent_alt;
        else tangent_normal=TN::normal;
      } else if(list[j].regexp(0,"^([iaAmMCcqQzZlLHhvV]|AA)$",mAT,0)){
        ptype=SvgmlPoints(string_isin_pos(list[j].v(),SvgmlPoints_g_));
        if(is_arc(ptype) || ptype==TP::AA){
          parameters.clear();
          int numP=(ptype==TP::AA)?1:5;
          for(int k=j+1;k<=j+numP;k++){
            if(k>=list.num()){
              throw MyTSchar("arc not valid. line='%s'",line_.v());
            }
            double d=strtod(list[k].v(),&endptr);
            if(*endptr=='\0'){
              // ok
            } else if(list[k].regexp(0,":")){
              d=svgml.evaluate_expression(list[k].v(),line_.v());
            } else {
              throw MyTSchar("arc not valid. line='%s'",line_.v()); 
            }
            parameters.append(d);
          }
          j+=numP;
        } else if(is_zZ(ptype)){
          if(icoord>0 || tangent_normal!=TN::none || connectionP!=TPC::none){
            throw MyTSchar("Z not valid. line='%s'",line_.v());
          }
          points_.incr_num();
          points_[end_MTS].ptype_=ptype;
        }
        continue;
      } else if(list[j].regexp(0,"^(vertex|ariste|face|segment|segment_inverse)$",mAT,0)){
        connectionP=SvgmlPointsConnections(string_isin_pos(list[j].v(),
          SvgmlPointsConnections_g_));
        if(j==list.num()-1){
          throw MyTSchar("vertex|ariste|face|segment|segment_inverse "
            "has no entity number. line='%s'",line_.v());
        }
        connectionN[0]=strtol(list[j+1].v(),&endptr,10);
        if(*endptr!='\0'){
          throw MyTSchar("vertex|ariste|face|segment|segment_inverse has no "
            "valid entity number. line='%s'",line_.v());
        }
        if(is_any_segment(connectionP)){
          if(j==list.num()-2){
            throw MyTSchar("segment|segment_inverse "
              "need 2 entity numbers. line='%s'",line_.v());
          }
          connectionN[1]=strtol(list[j+2].v(),&endptr,10);
          if(*endptr!='\0'){
            throw MyTSchar("segment|segment_inverse has no "
              "valid entity number. line='%s'",line_.v());
          }
          j++;
        }
        j++;
      } else {
        throw MyTSchar("incorrect format in '%s'. line='%s'",list[j].v(),line_.v());
      }
      int next_is_number=0,next_is_number_last=0;
      if(j<list.num()-1 && (is_number(list[j+1].v()) || list[j+1].regexp(0,":"))){
        next_is_number=1;
        if(j==list.num()-2){
          next_is_number_last=1;
        } else if(is_number(list[j+2].v())==0 && list[j+2].regexp(0,":")==0){
          next_is_number_last=1;
        }
      }
      if(connectionP!=TPC::none){
        if(connectionP==TPC::ariste && tangent_normal!=TN::none) /* go*/;
        else if(connectionP==TPC::ariste && icoord<1) continue;
        else if(connectionP==TPC::ariste && icoord==1 && next_is_number) continue;
        if(connectionP==TPC::face && icoord<2) continue;
        if(connectionP==TPC::face && icoord==2 && next_is_number) continue;
        
        if(tangent_normal!=TN::none){
          if(points_.num()==0){
            throw MyTSchar("incorrect line line='%s'",line_.v());
          }
          point=points_[end_MTS].pointG_;
        }
        points_.incr_num();
        points_[end_MTS].ptype_=to_absolute(ptype);
        points_[end_MTS].pointG_=point;
        id_parentList[0]->calculate_connection_point(connectionP,connectionN,
          tangent_normal,icoord,points_,svgml);
      } else {
        if(is_HhVv(ptype) || ptype==TP::i){
          if(icoord<1) continue;
          if(is_Vv(ptype)){
            point[1]=point[0];
            point[0]=0.0;
          } else if(ptype==TP::i){
            if(points_.num()<2){
              throw MyTSchar("incorrect line 'i' needs previous points. line='%s'",line_.v());
            }
          }
        } else if(icoord<2 || (icoord==2 && next_is_number_last)){
          continue;
        }
        points_.incr_num();
        points_[end_MTS].ptype_=ptype;
        points_[end_MTS].point_=point;
        this->transform(points_[end_MTS],id_parentList);
        points_[end_MTS].pointG_=points_[end_MTS].point_;
        
        if(ptype==TP::i){
          dvec3 n=normalize(points_[end_MTS-1].pointG_-points_[end_MTS-2].pointG_);
          points_[end_MTS].point_=point[0]*n;
          points_[end_MTS].pointG_=points_[end_MTS].point_;
          points_[end_MTS].ptype_=TP::l;
        }
        if(!is_absolute(ptype)){
          int k;
          for(k=points_.num()-2;k>=0;k--){
            if(is_point(points_[k].ptype_)){
              break;
            }
          }
          if(k>=0){
            points_[end_MTS].pointG_+=points_[k].pointG_;
          }
        }
      }
      if(is_arc(ptype)){
        double rx=parameters[0]/100.0*id_parentList[0]->bbox_[2];
        double ry=parameters[1]/100.0*id_parentList[1]->bbox_[3];
        parameters[0]=rx;
        parameters[1]=ry;
        points_[end_MTS].parameters_=parameters;
      } else if(ptype==TP::AA){
        double r=parameters[0]/100.0*id_parentList[0]->bbox_[2];
        parameters[0]=r;
        points_[end_MTS].parameters_=parameters;
      }
      if(points_.num()>1 && points_[end_MTS-1].ptype_==TP::C){
        points_[end_MTS].ptype_=TP::CC;
      } else if(points_.num()>1 && points_[end_MTS-1].ptype_==TP::c){
        points_[end_MTS].ptype_=TP::cc;
      }
      point=dvec3(); icoord=0; parameters.clear();
      tangent_normal=TN::none;
      connectionP=TPC::none;
      id_parentList[0]=id_parentList[1]=id_parentList[2]=id_parent;
      switch(properties_[i].name_){
        case OP::point: ptype=TP::p; break;
        case OP::delta_point: ptype=TP::dp; break;
        case OP::width_height: ptype=TP::width_height; break;
      }
    }
    if(icoord>0){
      throw MyTSchar("coordinates not correct. line='%s'",line_.v());
    }
  }
  int point_num=1;
  for(int i=0;i<points_.num();i++){
    if(is_point(points_[i].ptype_)){
      points_[i].point_num_=point_num++;
    }
  }
  
//################################################################################
//    converting AA to A
//################################################################################
  
  const double eps=0.001;
  
  for(int i=0;i<points_.num();i++){
    if(points_[i].ptype_!=TP::AA) continue;
    if(i==points_.num()-1){
      throw MyTSchar("AA not correct. line='%s'",line_.v());
    }
    double r=points_[i].parameters_[0];
    int p1=i-1,p2=i,p3=i+1;
    if(is_zZ(points_[p3].ptype_)){
      p3=0;
    }
    if(i==0) p1=points_.num()-1;
    if(is_zZ(points_[p1].ptype_)){
      p1--;
    }
    dvec3 pI=points_[i].pointG_;
    dvec3 p12=points_[p1].pointG_-points_[p2].pointG_;
    dvec3 p32=points_[p3].pointG_-points_[p2].pointG_;
    double norm12=l2Norm(p12);
    double norm32=l2Norm(p32);
    double angle=acos(glm::dot(p12,p32)/(norm12*norm32));
    double L=r/tan(angle/2.0);
    double alpha12=L/norm12;
    dvec3 p1_n=points_[p2].pointG_+alpha12*p12;
    double alpha32=L/norm32;
    dvec3 p2_n=points_[p2].pointG_+alpha32*p32;
    double sweep_flag=0;
    dvec3 c=cross(p12,p32);
    if(c[2]<0.0){
      sweep_flag=1; 
    }
    if(alpha12>1.0+eps || alpha32>1.0+eps){
      throw MyTSchar("AA not correct. Radius too big line='%s'",line_.v());
    }
    int point_num=points_[i].point_num_;
    points_.clear(i);
    points_.insert(i);
    points_[i].ptype_=TP::p;
    points_[i].pointG_=points_[i].point_=p1_n;
    points_[i].point_num_=point_num;
    i++;

    points_.insert(i);
    points_[i].ptype_=TP::A;
    points_[i].pointG_=points_[i].point_=p2_n;
    points_[i].parameters_={r,r,0,0,sweep_flag};
    points_[i].point_num_=point_num+1;
    if(i<points_.num()-1 && !is_absolute(points_[i+1].ptype_)){
      points_[i+1].point_-=points_[i].pointG_-pI;
    }
    for(int j=i+1;j<points_.num();j++){
      if(points_[j].point_num_!=0) points_[j].point_num_++;
    }
    if(alpha12>1.0-eps && i>1){
      if(p1>=i) p1++;
      points_[i-1].connectionP_=TPC::vertex;
      points_[i-1].connectionN_=points_[p1].point_num_;
      points_[i-1].connection_entity_=id_;
    }
    if(alpha32>1.0-eps){
      if(p3>=i) p3++;
      points_[i].connectionP_=TPC::vertex;
      points_[i].connectionN_=points_[p3].point_num_;
      points_[i].connection_entity_=id_;
    }
  }
}

// x,y where values are: -1,0,1
dvec3 SvgmlEntity::give_anchor_axes()
{
  dvec3 xy;
  
  MyTSchar* anchorTS=this->give_property(OP::anchor);
  if(anchorTS){
    if(anchorTS->regexp(0,"w")){
      if(anchorTS->regexp(0,"e")){
        xy[0]=0;
      } else {
        xy[0]=1;
      }
    } else if(anchorTS->regexp(0,"e")){
      xy[0]=-1;
    }
    if(anchorTS->regexp(0,"n")){
      if(anchorTS->regexp(0,"s")){
        xy[1]=0;
      } else {
        xy[1]=1;
      }
    } else if(anchorTS->regexp(0,"s")){
      xy[1]=-1;
    }
  }
  return xy;
}

static void set_bbox(dvec4& bbox,dvec3 point)
{
  for(int i=0;i<2;i++){
    bbox[i]=point[i];
  }
}

static void add_to_bbox(dvec4& bbox,dvec3 point)
{
  for(int i=0;i<2;i++){
    if(point[i]<bbox[i]){
      bbox[i+2]+=bbox[i]-point[i];
      bbox[i]=point[i];
    }
    if(point[i]>bbox[i]+bbox[i+2]){
      bbox[i+2]=point[i]-bbox[i];
    }
  }
}

static void add_to_bbox(dvec4& bbox,const dvec4& bbox_add)
{
  for(int i=0;i<2;i++){
    if(bbox_add[i]<bbox[i]){
      bbox[i+2]+=bbox[i]-bbox_add[i];
      bbox[i]=bbox_add[i];
    }
    if(bbox_add[i]+bbox_add[i+2]>bbox[i]+bbox[i+2]){
      bbox[i+2]=bbox_add[i]+bbox_add[i+2]-bbox[i];
    }
  }
}

void SvgmlPoint::output_gid(MyTSchar& out,Svgml& svgml,SvgmlEntity& entity)
{
  if(gid_numbers_[0]>0){
    out.printE(" {{num %d}}",gid_numbers_[0]);
  } else if(connectionP_==TPC::vertex || is_any_segment(connectionP_)){
    SvgmlEntity* entityREF=svgml.give_entity(connection_entity_.v(),entity.id_.v());
    if(entityREF->cmd_==OC::copy){
      entityREF=entityREF->give_copy_real_id(svgml);
    }
    SvgmlPoint* p=entityREF->give_pointPN(connectionN_);
    if(!p){
      throw MyTSchar("point not correct. line='%s'",entity.line_.v());
    }
    if(p->gid_numbers_[0]==0){
      out.printE(" {{} %g %g %g}",pointG_[0],pointG_[1],pointG_[2]);
      gid_numbers_[0]=++svgml.gid_numbers_[0];
      p->gid_numbers_[0]=gid_numbers_[0];
    } else {
      out.printE(" {{num %d}}",p->gid_numbers_[0]);
      gid_numbers_[0]=p->gid_numbers_[0];
    }
  } else {
    out.printE(" {{} %g %g %g}",pointG_[0],pointG_[1],pointG_[2]);
    gid_numbers_[0]=++svgml.gid_numbers_[0];
  }
}

static int is_same_point(SvgmlPoint& p1,SvgmlPoint& p2,Svgml& svgml,
  SvgmlEntity& entity)
{
  int num1=p1.gid_numbers_[0];
  if(num1==0){
    if(p1.connectionP_==TPC::vertex || is_any_segment(p1.connectionP_)){
      SvgmlEntity* entityREF=svgml.give_entity(p1.connection_entity_.v(),entity.id_.v());
      if(entityREF->cmd_==OC::copy){
        entityREF=entityREF->give_copy_real_id(svgml);
      }
      SvgmlPoint* p=entityREF->give_pointPN(p1.connectionN_);
      if(p && p->gid_numbers_[0]>0) num1=p->gid_numbers_[0];
      if(p && p==&p2) return 1;
    }
  }
  int num2=p2.gid_numbers_[0];
  if(num2==0){
    if(p2.connectionP_==TPC::vertex || is_any_segment(p2.connectionP_)){
      SvgmlEntity* entityREF=svgml.give_entity(p2.connection_entity_.v(),entity.id_.v());
      if(entityREF->cmd_==OC::copy){
        entityREF=entityREF->give_copy_real_id(svgml);
      }
      SvgmlPoint* p=entityREF->give_pointPN(p2.connectionN_);
      if(p && p->gid_numbers_[0]>0) num2=p->gid_numbers_[0];
    }
  }
  if(num1!=0 && num1==num2) return 1;
  return 0;
}

static void output_gid_point(double x,double y,double z,MyTSchar& out)
{
  out.printE(" {{} %g %g %g}",x,y,z);
}

static void output_gid_last_point(MyTSchar& out)
{
  out.printE(" {{num last}}");
}

static void output_gid_last_point_n(MyTSchar& out,int n)
{
  out.printE(" {{num last-%d}}",n);
}

// do not confuse point_num with ipoint
SvgmlPoint* SvgmlEntity::give_pointPN(int point_num)
{
  for(int i=0;i<points_.num();i++){
    if(points_[i].point_num_==point_num) return &points_[i];
  }
  return NULL;
}

void SvgmlEntity::output_gid(MyTSchar& out,MyTSvec<SvgmlPoint,3>& points,
  int styleEntity,Svgml& svgml)
{
  MyTSchar group=id_;
  group.regsub(0,"\\.","//");
  out.printE("<a n='create_group' a='-ifnotexists 1 -set_as_default 1 "
    "{Name {%s} IsLayer 1}'/>\n",group.v());
 
  const double eps=0.001;
 
  int i_start=0,is_closed=0; MyTSint lines;
  for(int i=1;i<points.num();i++){
    if(is_same_point(points[i_start],points[i],svgml,*this)){
      i_start=i;
    } else if(is_any_segment(points[i].connectionP_) && 
      is_any_segment(points[i_start].connectionP_) &&
      strcmp(points[i].connection_entity_.v(),
      points[i_start].connection_entity_.v())==0){
      int point_num=(points[i].connectionN_<points[i_start].connectionN_)?
        points[i].connectionN_:points[i_start].connectionN_;
      SvgmlEntity* entity=svgml.give_entity(points[i].connection_entity_.v(),id_.v());
      if(entity->cmd_==OC::copy){
        entity=entity->give_copy_real_id(svgml);
      }
      SvgmlPoint* p=entity->give_pointPN(points[i_start].connectionN_);
      points[i_start].gid_numbers_[0]=p->gid_numbers_[0];
      p=entity->give_pointPN(points[i].connectionN_);
      if(!p){
        throw MyTSchar("point not correct. line='%s'",line_.v());
      }
      points[i].gid_numbers_[0]=p->gid_numbers_[0];
      p=entity->give_pointPN(point_num);
      if(!p){
        throw MyTSchar("point not correct. line='%s'",line_.v());
      }
      if(gid_start_numbers_[0]==0){
        gid_start_numbers_[0]=points[i_start].gid_numbers_[0];
      }
      if(gid_start_numbers_[1]==0){
        gid_start_numbers_[1]=p->gid_numbers_[1];
      }
      lines.append(p->gid_numbers_[1]);
      points[i_start].gid_numbers_[1]=p->gid_numbers_[1];
      i_start=i;
    } else if(is_arc(points[i].ptype_)){
      vec2 r;
      r[0]=points[i].parameters_[0];
      r[1]=points[i].parameters_[1];
      float phi=fmod(DEGTORAD*points[i].parameters_[2],2*M_PI);
      float cos_phi=cos(phi);
      float sin_phi=sin(phi);
      int largeArcFlag=int(points[i].parameters_[3]);
      int sweepFlag=int(points[i].parameters_[4]);
            
      mat2 mat_rot;
      mat_rot[0]=vec2(cos_phi,-sin_phi);
      mat_rot[1]=vec2(sin_phi,cos_phi);
      
      vec2 c0,c1,center;
      float angleStart,angleExtent,angleMid;
      c0=vec2(points[i_start].pointG_[0],points[i_start].pointG_[1]);
      c1=vec2(points[i].pointG_[0],points[i].pointG_[1]);
      computeArc(c0,r,phi,largeArcFlag,sweepFlag,c1,center,angleStart,angleExtent);
      
      angleMid=angleStart+0.5*angleExtent;
      vec2 pmid=mat_rot*vec2(r[0]*cos(angleMid),r[1]*sin(angleMid))+center;
      out.printE("<a n='create_line' a='arcline {");
      if(i_start==0 || is_vertex_segment(points[i_start].connectionP_)){
        points[i_start].output_gid(out,svgml,*this);
      } else {
        output_gid_last_point(out);
      }
      output_gid_point(pmid[0],pmid[1],points[i].pointG_[2],out);
      points[i].output_gid(out,svgml,*this);
      out.printE("}'/>\n");
      points[i_start].gid_numbers_[1]=++svgml.gid_numbers_[1];
      lines.append(svgml.gid_numbers_[1]);
      if(gid_start_numbers_[0]==0){
        gid_start_numbers_[0]=points[i_start].gid_numbers_[0];
      }
      if(gid_start_numbers_[1]==0){
        gid_start_numbers_[1]=svgml.gid_numbers_[1];
      }
      i_start=i;
    } else if(is_point(points[i].ptype_) && is_qc(points[i-1].ptype_)){
      out.printE("<a n='create_line' a='-tangent0 point -tangent1 point NURBSline {");
      if(i_start==0 || is_vertex_segment(points[i_start].connectionP_)){
        points[i_start].output_gid(out,svgml,*this);
      } else {
        output_gid_last_point(out);
      }
      points[i_start+1].output_gid(out,svgml,*this);
      points[i-1].output_gid(out,svgml,*this);
      points[i].output_gid(out,svgml,*this);
      out.printE("}'/>\n");
      points[i_start].gid_numbers_[1]=++svgml.gid_numbers_[1];
      lines.append(svgml.gid_numbers_[1]);
      if(gid_start_numbers_[0]==0){
        gid_start_numbers_[0]=points[i_start].gid_numbers_[0];
      }
      if(gid_start_numbers_[1]==0){
        gid_start_numbers_[1]=svgml.gid_numbers_[1];
      }
      i_start=i;
    } else if(is_point(points[i].ptype_)){
      if(gid_start_numbers_[0]==0){
        gid_start_numbers_[0]=points[i_start].gid_numbers_[0];
      }
      SvgmlPoint* p2=&points[i];
      if(i==points.num()-2 && is_zZ(points[i+1].ptype_) &&
        length(points[i].pointG_-points[0].pointG_)<eps){
        p2=&points[0];
        is_closed=1;
      }
      if(!is_same_point(points[i_start],*p2,svgml,*this)){
        out.printE("<a n='create_line' a='line {");
        if(i_start==0 || is_vertex_segment(points[i_start].connectionP_)){
          points[i_start].output_gid(out,svgml,*this);
        } else {
          output_gid_last_point(out);
        }
        if(i==points.num()-2 && is_zZ(points[i+1].ptype_) &&
          length(points[i].pointG_-points[0].pointG_)<eps){
          int n=svgml.gid_numbers_[0]-gid_start_numbers_[0];
          output_gid_last_point_n(out,n);
          SvgmlPoint* p=this->give_pointPN(1);
          points[i].gid_numbers_[0]=p->gid_numbers_[0];
          is_closed=1;
        } else {
          points[i].output_gid(out,svgml,*this);
        }
        out.printE("}'/>\n");
        points[i_start].gid_numbers_[1]=++svgml.gid_numbers_[1];
        lines.append(svgml.gid_numbers_[1]);
        if(gid_start_numbers_[1]==0){
          gid_start_numbers_[1]=svgml.gid_numbers_[1];
        }
      }
      i_start=i;
    } else if(is_zZ(points[i].ptype_)){
      if(is_closed) break;
      if(gid_start_numbers_[0]==0){
        gid_start_numbers_[0]=points[i_start].gid_numbers_[0];
      }
      if(!is_same_point(points[i_start],points[0],svgml,*this)){
        out.printE("<a n='create_line' a='line {");
        if(i_start==0 || is_vertex_segment(points[i_start].connectionP_)){
          points[i_start].output_gid(out,svgml,*this);
        } else {
          output_gid_last_point(out);
        }
        int n=svgml.gid_numbers_[0]-gid_start_numbers_[0];
        output_gid_last_point_n(out,n);
        out.printE("}'/>\n");
        points[i_start].gid_numbers_[1]=++svgml.gid_numbers_[1];
        lines.append(svgml.gid_numbers_[1]);
        if(gid_start_numbers_[1]==0){
          gid_start_numbers_[1]=svgml.gid_numbers_[1];
        }
      }
      i_start=i;
    }
  }
  MyTSchar* fill=svgml.give_property(styleEntity,OP::fill);
  if(fill && strcmp(fill->v(),"none")!=0){
    out.printE("<a n='create_surface' a='by_contour {");
    for(int i=0;i<lines.num();i++){
      if(i>0) out.printE(" ");
      out.printE("%d",lines[i]);
    }
    out.printE("}'/>\n");
    svgml.gid_numbers_[2]+=1;
    gid_start_numbers_[2]=svgml.gid_numbers_[2];
  }
}

void SvgmlEntity::give_from_entities(Svgml& svgml,MyTSint& entities)
{
  int parent=svgml.give_entityN(id_parent_.v(),id_.v());
  
  MyTSint entities0;
  MyTSchar* from=this->give_property(OP::from);
  if(from){
    MyTScharList idsList;
    string_split_text_sep(from->v(),-1,",",idsList);
    for(int i=0;i<idsList.num();i++){
      MyTSchar mATS[2];
      if(idsList[i].regexp(0,"(\\S+)",mATS,2)==0){
        throw MyTSchar("error with 'from' '%s' not valid -A-. line='%s'",
          idsList[i].v(),line_.v());
      }
      int num=svgml.give_entityN(mATS[1].v(),id_.v());
      if(num==-1){
        throw MyTSchar("error with 'from' '%s' not valid -B-. line='%s'",
          mATS[1].v(),line_.v());
      }
      entities0.append(num);
    }
  } else {
    entities0.append(parent);
    MyTSchar* include_children=this->give_property(OP::include_children);
    if(include_children && strcmp(include_children->v(),"1")==0){
      MyTSchar id("%s.%s",id_parent_.v(),id_short_.v());
      svgml.give_descendants(id_parent_.v(),id.v(),entities0);
    }
  }
  for(int i=0;i<entities0.num();i++){
    SvgmlEntity& e=svgml.entities_[entities0[i]];
    if(e.cmd_!=OC::copy){
      entities.append(entities0[i]);
    } else {
      for(int j=0;j<svgml.entities_.num();j++){
        if(strncmp(svgml.entities_[j].id_.v(),e.id_.v(),e.id_.num())!=0) continue;
        if(svgml.entities_[j].id_.regexp(e.id_.num(),"\\A\\.__\\d+\\__")==0) continue;
        entities.append(j);
      }
    }
  }
}

// font_family, font_size must have default values
// fill,stroke can be color,none or NULL
// They will return updated and style might be updated
void Svgml::check_add_font_and_size(int styleEntity,MyTSchar& font_family,
  FT_FontWeight& fweight,FT_FontStyle& fstyle,double& font_size,
  const char* fill,const char* stroke,MyTSchar& style)
{
  int found=0;
  if(styleEntity!=-1){
    MyTSchar* font_familyP=this->give_property(styleEntity,OP::font_family);
    if(font_familyP){
      font_family=*font_familyP;
      font_family.regsub(0,",.*$","");
      font_family.regsub(0,"^\\s*\"|\"\\s*$","");
      found=1;
    }
  }
  if(!found){
    style.printE("font-family: %s,sans-serif;",font_family.v());
  }
  
  fweight=FW::normal; fstyle=FS::normal;
  if(styleEntity!=-1){
    MyTSchar* font_weightP=this->give_property(styleEntity,OP::font_weight);
    const char* boldList[]={"bold","700",NULL};
    if(font_weightP && string_isin_pos(font_weightP->v(),boldList)!=-1){
      fweight=FW::bold;
    }
    MyTSchar* font_styleP=this->give_property(styleEntity,OP::font_style);
    if(font_styleP && strcmp(font_styleP->v(),"italic")==0){
      fstyle=FS::italic;
    } else if(font_styleP && strcmp(font_styleP->v(),"oblique")==0){
      fstyle=FS::oblique;
    }
  }
  
  found=0;
  if(styleEntity!=-1){
    MyTSchar* font_sizeP=this->give_property(styleEntity,OP::font_size);
    if(font_sizeP){
      font_size=atof(font_sizeP->v());
      found=1;
    }
  }
  if(!found){
    style.printE("font-size: %gpx;",font_size);
  }
  if(fill){
    found=0;
    MyTSchar* fillP=this->give_property(styleEntity,OP::fill);
    if(fillP){
      if(strcmp(fill,"none")!=0 && strcmp(fillP->v(),"none")!=0){
        found=1;
      }
      if(strcmp(fill,"none")==0 && strcmp(fillP->v(),"none")==0){
        found=1;
      }
      if(strcmp(fillP->v(),"white")==0){
        found=0;
      }
    }
    if(!found){
      style.printE("fill:%s;",fill);  
    }
  }
  if(stroke){
    found=0;
    MyTSchar* strokeP=this->give_property(styleEntity,OP::stroke);
    if(strokeP){
      if(strcmp(stroke,"none")!=0 && strcmp(strokeP->v(),"none")!=0){
        found=1;
      }
      if(strcmp(stroke,"none")==0 && strcmp(strokeP->v(),"none")==0){
        found=1;
      }
    }
    if(!found){
      style.printE("stroke:%s;",stroke);  
    }
  }
}

void SvgmlEntity::create(int entity_num,MyTSchar& out,Svgml& svgml,Svgml_copy* copy_info)
{
  MyTSchar mAT[3];
  
  dvec3 anchor=this->give_anchor_axes();
  
  if(!is_calculated_){
    if(points_.num()==0){
      this->calculate_points(svgml,copy_info);
    }
    if(copy_info){
      this->copy_operation(svgml,*copy_info);
    }
    
//     int is_init=(copy_info)?copy_info->init_bbox_:0;
    //dvec4& bbox=(copy_info)?copy_info->entity_->bbox_:bbox_;
    int is_init=0;
    dvec4& bbox=bbox_;
    
    for(int i=0;i<points_.num();i++){
      if(cmd_==OC::copy) break;
      if(is_zZ(points_[i].ptype_)) continue;
      if(points_[i].ptype_==TP::width_height){
        int j;
        for(j=i-1;j>=0;j--){
          if(is_point(points_[j].ptype_)){
            break;
          }
        }
        if(j>=0){
          dvec3 point=points_[j].pointG_;
          for(int k=0;k<3;k++){
            if(anchor[k]==0) point[k]-=0.5*points_[i].point_[k];
            else if(anchor[k]==-1) point[k]-=points_[i].point_[k];
          }
          if(!is_init){
            set_bbox(bbox,point);
            is_init=1;
            if(copy_info) copy_info->init_bbox_=1;
          } else {
            add_to_bbox(bbox,point);
          }
          point+=points_[i].point_;
          add_to_bbox(bbox,point);
        }
      } else {
        if(!is_init){
          set_bbox(bbox,points_[i].pointG_);
          is_init=1;
        } else {
          add_to_bbox(bbox,points_[i].pointG_);
        }
      }
    }
    if(copy_info){
      if(copy_info->init_bbox_==0){
        svgml.entities_[copy_info->entity_].bbox_=bbox_;
        copy_info->init_bbox_=1;
      } else {
        add_to_bbox(svgml.entities_[copy_info->entity_].bbox_,bbox_);
      }
    }
    is_calculated_=1;
  }
    
  MyTSchar style;
  style.print0("");
  int styleEntity=-1;
  MyTSchar* cclass=this->give_property(OP::cclass);
  if(cclass){
    int found=0;
    for(int i=0;i<svgml.entities_.num();i++){
      if(svgml.entities_[i].cmd_!=OC::cclass) continue;
      if(strcmp(&svgml.entities_[i].id_[1],cclass->v())==0){
        styleEntity=i;
        style=svgml.entities_[i].contents_;
        found=1;
        break;
      }
    }
    if(!found){
      throw MyTSchar("unknown class '%s'. line='%s'",cclass->v(),line_.v());
    }
  }
  if(copy_info && copy_info->style_.num()){
    style=copy_info->style_;
    styleEntity=copy_info->styleEntity_;
  }
  
  switch(cmd_){
    case OC::region:
    {
      if(!is_calculated_){
        throw MyTSchar("region needs a point definition. line='%s'",line_.v());
      }
    }
    break;
    case OC::image:
    {
      MyTSchar* text=this->give_property(OP::text);
      if(!text){
        throw MyTSchar("image needs a text property with the fileName. line='%s'",
          line_.v());
      }
      MyTSchar contents,contentsB64,preserveAspectRatio;
      const char* format;
      const char* ext=file_extension(text->v());
      if(ext==NULL){
        break;
      } else if(strcmp(ext,".png")==0){
        format="png";
      } else if(strcmp(ext,".svg")==0){
        format="svg+xml";
      } else {
        throw MyTSchar("image file format not supported. .png .svg. line='%s'",
          line_.v());
      }
      read_fileG(text->v(),contents,1);
      size_t max_size=contents.num()*1.35+10;
      contentsB64.set_num(max_size);
      size_t len=b64_encode(contents.v(),contents.num(),contentsB64.v(),
        contentsB64.num(),80);
      if(len==-1){
        throw MyTSchar("image problems base64. line='%s'",line_.v());
      }
      contentsB64.print(len,"");
      MyTSchar* anchorTS=this->give_property(OP::anchor);
      if(anchorTS && anchor[0]==0 && anchor[1]==0){
        preserveAspectRatio.print0("none");
      } else {
        preserveAspectRatio.print0("xMinYMin");
      }
      if(svgml.otype_==OTS::svg){
        out.printE("<image x='%.3g' y='%.3g' width='%.3g' height='%.3g' id='%s' style='%s' "
          "xlink:href='data:image/%s;base64,%s' preserveAspectRatio='%s'/>\n",
          bbox_[0],bbox_[1],bbox_[2],bbox_[3],id_.v(),style.v(),format,contentsB64.v(),
          preserveAspectRatio.v());
        MyTSchar* border_stroke_width=svgml.give_property(styleEntity,OP::border_stroke_width);
        if(border_stroke_width && border_stroke_width->regexp(0,"((\\d+)[^;]+)",mAT,3) &&
          atof(mAT[2].v())!=0){
          MyTSchar* border_stroke=svgml.give_property(styleEntity,OP::border_stroke);
          MyTSchar styleB=style;
          if(border_stroke){
            styleB.printE("stroke-width:%s;stroke:%s;fill:none;",mAT[1].v(),border_stroke->v());
          } else {
            styleB.printE("stroke-width:%s;stroke:black;fill:none;",mAT[1].v(),border_stroke->v()); 
          }
          double width=bbox_[2];
          double height=bbox_[3];
          if(strcmp(ext,".png")==0 && strcmp(preserveAspectRatio.v(),"none")!=0){
            int widthIMG,heightIMG;
            pngsize_data(contents,widthIMG,heightIMG);
            double r1=double(width)/height;
            double r2=double(widthIMG)/heightIMG;
            if(r2>r1){
              height*=r1/r2;
            } else {
              width*=r2/r1;
            }
          }
          out.printE("<rect x='%.3g' y='%.3g' width='%.3g' height='%.3g' "
            "id='%s-border' style='%s'/>\n",
            bbox_[0],bbox_[1],width,height,id_.v(),styleB.v());
        }
      }
    }
    break;
    case OC::rect:
    {
      if(svgml.otype_==OTS::svg){
        out.printE("<rect x='%.3g' y='%.3g' width='%.3g' height='%.3g' "
          "id='%s' style='%s'",bbox_[0],bbox_[1],bbox_[2],bbox_[3],id_.v(),style.v());
        MyTSchar* border_radius=svgml.give_property(styleEntity,OP::border_radius);
        if(border_radius && border_radius->regexp(0,"((\\d+)[^;]+)",mAT,3) &&
          atof(mAT[2].v())!=0){
          out.printE(" rx='%.3g' ry='%.3g'",atof(mAT[2].v()),atof(mAT[2].v()));
        }
        out.printE("/>\n");
      } else if(svgml.otype_==OTS::gid){
        MyTSchar group=id_;
        group.regsub(0,"\\.","//");
        out.printE("<a n='create_group' a='-ifnotexists 1 -set_as_default 1 "
          "{Name {%s} IsLayer 1}'/>\n",group.v());
        for(int i=0;i<4;i++){
          gid_start_numbers_[i]=svgml.gid_numbers_[i]+1;
        }
        out.printE("<a n='create_line' a='line {");
        dvec3 pnt;
        double z=points_[0].pointG_[2];
        for(int i=0;i<4;i++){
          switch(i){
            case 0: pnt=dvec3(bbox_[0],bbox_[1],z); break;
            case 1: pnt=dvec3(bbox_[0]+bbox_[2],bbox_[1],z); break;
            case 2: pnt=dvec3(bbox_[0]+bbox_[2],bbox_[1]+bbox_[3],z); break;
            case 3: pnt=dvec3(bbox_[0],bbox_[1]+bbox_[3],z); break;
          }
          out.printE("{{} %g %g %g} ",pnt[0],pnt[1],pnt[2]);
        }
        out.printE("{{coords_type close} 0.0 0.0 0.0}}'/>\n");
        MyTSchar* fill=svgml.give_property(styleEntity,OP::fill);
        if(fill && strcmp(fill->v(),"none")!=0){
          int l=gid_start_numbers_[1];
          out.printE("<a n='create_surface' a='by_contour {%d %d %d %d}'/>\n",
            l,l+1,l+2,l+3);
          svgml.gid_numbers_[2]+=1;
        }
        svgml.gid_numbers_[0]+=4;
        svgml.gid_numbers_[1]+=4;
      }
    }
    break;
    case OC::circle:
    {
      dvec3 c;
      c[0]=bbox_[0]+0.5*bbox_[2];
      c[1]=bbox_[1]+0.5*bbox_[3];
      double r=0.5*bbox_[2];
      if(svgml.otype_==OTS::svg){
        out.printE("<circle cx='%.3g' cy='%.3g' r='%.3g' "
          "id='%s' style='%s'/>\n",c[0],c[1],r,id_.v(),style.v());
      } else {
      
      }
    }
    break;
    case OC::cube:
    {
      SvgmlPointsConnections label=TPC::none;
      MyTSchar* labelsTS=this->give_property(OP::labels);
      if(labelsTS){
        int pos=string_isin_pos(labelsTS->v(),SvgmlPointsConnections_g_);
        if(pos!=-1){
          label=SvgmlPointsConnections(pos);
        } else if(strcmp(labelsTS->v(),"0")==0 || strcmp(labelsTS->v(),"")==0){
          label=TPC::none;
        } else if(strcmp(labelsTS->v(),"1")==0){
          label=TPC::all;
        } else {
          throw MyTSchar("unrecognized 'labels' value. line='%s'",line_.v());
        }
      }
      if(label!=TPC::none){
        style.printE("fill:none;");
      }
      this->process_cube(label,style,out,svgml);
    }
    break;
    case OC::line:
    {
      MyTScharList labelsList;
      MyTSchar* labelsTS=NULL;
      int labelsFlag=0;
      if(copy_info && copy_info->labels_.num()) labelsTS=&copy_info->labels_;
      else labelsTS=this->give_property(OP::labels);
      if(labelsTS && svgml.otype_==OTS::svg){
        if(strcmp(labelsTS->v(),"0")!=0 && strcmp(labelsTS->v(),"")!=0){
          labelsFlag=1;
          MyTSchar marker("url(#circle)");
          MyTSchar* stroke=svgml.give_property(styleEntity,OP::stroke);
          if(stroke){
            svgml.give_write_marker_id(marker,stroke->v(),out);
          }
          style.printE("marker-start:%s;marker-mid:%s;marker-end:%s;",
            marker.v(),marker.v(),marker.v());
        }
        string_split(labelsTS->v(),"\\s*,\\s*",labelsList);
        if(labelsList.num()<2) labelsList.set_num(0);
      }
      if(svgml.otype_==OTS::svg){
        MyTSchar ds;
        for(int i=0;i<points_.num();i++){
          if(points_[i].ptype_==TP::width_height){
            continue;
          } else if(ds.num()==0){
            ds.printE("M%.3g,%.3g",points_[i].pointG_[0],points_[i].pointG_[1]);
          } else if(i>0 && is_qc(points_[i-1].ptype_)){
            ds.printE(" %.3g,%.3g",points_[i].point_[0],points_[i].point_[1]);
          } else if(points_[i].ptype_==TP::p){
            ds.printE(" L%.3g,%.3g",points_[i].point_[0],points_[i].point_[1]);
          } else if(points_[i].ptype_==TP::dp){
            ds.printE(" l%.3g,%.3g",points_[i].point_[0],points_[i].point_[1]);
          } else if(points_[i].ptype_==TP::CC || points_[i].ptype_==TP::cc){
            ds.printE(" %.3g,%.3g",points_[i].point_[0],points_[i].point_[1]);
          } else if(is_arc(points_[i].ptype_)){
            ds.printE(" %s%.3g,%.3g,%.3g,%g,%g %.3g,%.3g",
              SvgmlPoints_g_[int(points_[i].ptype_)],
              points_[i].parameters_[0],points_[i].parameters_[1],points_[i].parameters_[2],
              points_[i].parameters_[3],points_[i].parameters_[4],
              points_[i].point_[0],points_[i].point_[1]);
          } else if(is_zZ(points_[i].ptype_)){
            ds.printE(" %s",SvgmlPoints_g_[int(points_[i].ptype_)]);
          } else if(is_Hh(points_[i].ptype_)){
            ds.printE(" %s%.3g",SvgmlPoints_g_[int(points_[i].ptype_)],
              points_[i].point_[0]);
          } else if(is_Vv(points_[i].ptype_)){
            ds.printE(" %s%.3g",SvgmlPoints_g_[int(points_[i].ptype_)],
              points_[i].point_[1]);
          } else {
            ds.printE(" %s%.3g,%.3g",SvgmlPoints_g_[int(points_[i].ptype_)],
              points_[i].point_[0],points_[i].point_[1]);
          }
        }
        out.printE("<path d='%s' id='%s' style='%s'/>\n",ds.v(),id_.v(),style.v());
        if(labelsFlag){
          MyTSchar label;
          for(int i=0,idx=0;i<points_.num();i++){
            if(!is_point(points_[i].ptype_)) continue;
            if(idx<labelsList.num()){
              label=labelsList[idx];
            } else {
              label.print0("%d",idx+1);
            }
            MyTSchar font_family("Montserrat");
            double font_size=12;
            MyTSchar styleT=style;
            FT_FontWeight fweight; FT_FontStyle fstyle;
            svgml.check_add_font_and_size(styleEntity,font_family,fweight,fstyle,
              font_size,"black","none",styleT);
            
            out.printE("<text x='%.3g' y='%.3g' text-anchor='start' style='%s'>\n",
              points_[i].pointG_[0]+0.2*font_size,
              points_[i].pointG_[1]-0.3*font_size,styleT.v());
            svgml.append_tspans(points_[i].pointG_[0]+5,label,out,
              font_family.v(),fweight,fstyle,font_size);
            out.printE("</text>\n");
            idx++;
          }
        }
      } else {
        this->output_gid(out,points_,styleEntity,svgml); 
      }
    }
    break;
    case OC::label: case OC::dimension: case OC::text:
    {
      dvec4 padding;
      dvec3 p0,p1,vT,vN,vNd,p0D1,p1D1,p0D2,p1D2,pLabel;
      MyTSchar text;
      
      for(int i=0;i<properties_.num();i++){
        if(properties_[i].name_!=OP::text) continue;
        text.printE("%s",properties_[i].value_.v());
      }
      MyTSchar font_family("Montserrat");
      double font_size=12;
      FT_FontWeight fweight; FT_FontStyle fstyle;
      svgml.check_add_font_and_size(styleEntity,font_family,fweight,fstyle,
        font_size,NULL,NULL,style);

      dvec4 text_box,text_box_line1;
      svgml.measure_tspans(text,font_family.v(),fweight,fstyle,font_size,text_box,text_box_line1);
      
      MyTSchar* horizontal_vertical=this->give_property(OP::horizontal_vertical);
      SvgmlPoint* delta_point=this->give_point(TP::dp);
      
      if(cmd_==OC::dimension){
        SvgmlEntity* parent=svgml.give_entity(id_parent_.v(),id_.v());
        
        if(points_.num()>=2){
          p0=points_[0].pointG_;
          vT=points_[1].pointG_-points_[0].pointG_;
          if(horizontal_vertical && strcmp(horizontal_vertical->v(),"v")==0){
            vN=dvec3(anchor[0],0,0);
          } else if(horizontal_vertical && strcmp(horizontal_vertical->v(),"h")==0){
            vN=dvec3(0,anchor[1],0);
          } else {
            vN=normalize(dvec3(-1*vT[1],vT[0],0));
            if(vN[0]==0) vN=dvec3(0,anchor[1],0);
            else if(vN[1]==0) vN=dvec3(anchor[0],0,0);
          }
        } else if(parent->cmd_==OC::rect){
          MyTSchar* ariste=this->give_property(OP::ariste);
          if(ariste && strcmp(ariste->v(),"n")==0){
            p0=dvec3(parent->bbox_[0],parent->bbox_[1],0);
            vT=dvec3(parent->bbox_[2],0,0);
            vN=dvec3(0,anchor[1],0);
          } else if(ariste && strcmp(ariste->v(),"w")==0){
            p0=dvec3(parent->bbox_[0],parent->bbox_[1],0);
            vT=dvec3(0,parent->bbox_[3],0);
            vN=dvec3(anchor[0],0,0);
          } else if(ariste && strcmp(ariste->v(),"e")==0){
            p0=dvec3(parent->bbox_[0]+parent->bbox_[2],parent->bbox_[1],0);
            vT=dvec3(0,parent->bbox_[3],0);
            vN=dvec3(anchor[0],0,0);
          } else {
            p0=dvec3(parent->bbox_[0],parent->bbox_[1]+parent->bbox_[3],0);
            vT=dvec3(parent->bbox_[2],0,0);
            vN=dvec3(0,anchor[1],0);
          }
        } else {
          throw MyTSchar("dimension not valid. Only two points or 'rect'  line='%s'",line_.v());
        }
        p1=p0+vT;
        
        if(horizontal_vertical && strcmp(horizontal_vertical->v(),"h")==0){
          vT[1]=0;
          if(vN[1]!=0){
            vN=dvec3(0,vN[1]/fabs(vN[1]),0);
          }
        } else if(horizontal_vertical && strcmp(horizontal_vertical->v(),"v")==0){
          vT[0]=0;
          if(vN[0]!=0){
            vN=dvec3(vN[0]/fabs(vN[0]),0,0);
          }
        }
        vN=0.8*font_size*vN;
        if(delta_point){
          vNd=delta_point->point_;
        } else {
          vNd=vN;
        }
        p0D1=p0+vNd;
        p1D1=p1+vNd;
        
        p0D2=p0D1+vN;
        p1D2=p1D1+vN;
        
        if(horizontal_vertical && strcmp(horizontal_vertical->v(),"h")==0){
          p1D1[1]=p0D1[1];
          p1D2[1]=p0D2[1];
        } else if(horizontal_vertical && strcmp(horizontal_vertical->v(),"v")==0){
          p1D1[0]=p0D1[0];
          p1D2[0]=p0D2[0];
        }
        pLabel=0.7*vN+0.5*(p0D1+p1D1);
      } else {
        pLabel=points_[0].pointG_;
        //pLabel=dvec3(bbox_[0],bbox_[1],0);
        vN=anchor;
      }
      if(svgml.otype_==OTS::svg){
        if(cmd_==OC::dimension){
          MyTSchar styleT("stroke:black;stroke-width:1px;%s",style.v());
          out.printE("<path d='M%.3g,%.3g L%.3g,%.3g' id='%s-DL1' style='%s'/>\n",p0[0],
            p0[1],p0D2[0],p0D2[1],id_.v(),styleT.v());
          out.printE("<path d='M%.3g,%.3g L%.3g,%.3g' id='%s-DL2' style='%s'/>\n",p1[0],
            p1[1],p1D2[0],p1D2[1],id_.v(),styleT.v());
          
          MyTSchar markerS("url(#TriangleInL)"),markerE("url(#TriangleOutL)");
          MyTSchar* stroke=svgml.give_property(styleEntity,OP::stroke);
          if(stroke){
            svgml.give_write_marker_id(markerS,stroke->v(),out);
            svgml.give_write_marker_id(markerE,stroke->v(),out);
          }
          styleT.printE("marker-start:%s;marker-end:%s;",markerS.v(),markerE.v());
          out.printE("<path d='M%.3g,%.3g L%.3g,%.3g' id='%s-DL' style='%s'/>\n",p0D1[0],
            p0D1[1],p1D1[0],p1D1[1],id_.v(),styleT.v());
        } else if(delta_point && l2Norm(delta_point->point_)>20){
          dvec3 p0D=pLabel+delta_point->point_;
          dvec3 p1D=pLabel+0.05*delta_point->point_;
          delta_point=NULL;
          
          MyTSchar styleT("stroke:black;stroke-width:1px;%s",style.v());
          MyTSchar markerE("url(#TriangleOutL)");
          MyTSchar* stroke=svgml.give_property(styleEntity,OP::stroke);
          if(stroke){
            svgml.give_write_marker_id(markerE,stroke->v(),out);
          }
          styleT.printE("marker-end:%s;",markerE.v());
          out.printE("<path d='M%.3g,%.3g L%.3g,%.3g' id='%s-DL' style='%s'/>\n",
            p0D[0],p0D[1],p1D[0],p1D[1],id_.v(),styleT.v());
          pLabel=p0D;
        }
        
        if(anchor[1]==1){
          pLabel[1]+=text_box_line1[1]+text_box_line1[3];
        } else if(anchor[1]==-1){
          pLabel[1]+=text_box[1]-text_box[3];
        }
        if(delta_point && cmd_!=OC::dimension){
          pLabel+=delta_point->point_;
        } else if(cmd_==OC::label){
          pLabel[0]+=0.5*anchor[0]*font_size;
        }
        const char* text_anchor;
        if(anchor[0]==-1){
          text_anchor="end";
        } else if(anchor[0]==1){
          text_anchor="start";
        } else {
          text_anchor="middle";
        }
        dvec3 plabelB,plabelB_WH;
        
        MyTSchar* border_stroke_width=svgml.give_property(styleEntity,OP::border_stroke_width);
        MyTSchar* border_fill=svgml.give_property(styleEntity,OP::border_fill);
        MyTScharList border_strokeList;
        if((border_stroke_width && atof(border_stroke_width->v())>0) || border_fill){
          MyTSchar styleT=style;
          if(border_stroke_width){
            styleT.printE("stroke-width:%s;",border_stroke_width->v());
          } else {
            styleT.printE("stroke-width:0px;");
          }
          MyTSchar* border_stroke=svgml.give_property(styleEntity,OP::border_stroke);
          if(border_stroke){
            string_split(border_stroke->v(),"[\\s,]+",border_strokeList);
            if(border_strokeList.num()==1){
              styleT.printE("stroke:%s;",border_stroke->v());
            } else {
              styleT.printE("stroke:none;");
            }
          } else {
            styleT.printE("stroke:black;");
          }
          if(border_fill){
            styleT.printE("fill:%s;",border_fill->v());
          } else {
            styleT.printE("fill:none;");
          }
          MyTSchar* paddingTS=svgml.give_property(styleEntity,OP::padding);
          if(paddingTS){
            MyTScharList list;
            string_split(paddingTS->v(),paddingTS->num(),"\\s+",list);
            switch(list.num()){
              case 1:
              {
                padding[0]=padding[1]=padding[2]=padding[3]=atof(list[0].v());
              }
              break;
              case 2:
              {
                padding[0]=padding[2]=atof(list[0].v());
                padding[1]=padding[3]=atof(list[1].v());
              }
              break;
              case 3:
              {
                padding[0]=atof(list[0].v());
                padding[1]=padding[3]=atof(list[1].v());
                padding[2]=atof(list[2].v());
              }
              break;
              case 4:
              {
                // top right bottom left
                for(int i=0;i<4;i++){
                  padding[i]=atof(list[i].v());
                }
              }
              break;
            }
          } else {
            padding[0]=padding[1]=padding[2]=padding[3]=0.8*font_size;
          }
          plabelB=pLabel;
          if(anchor[0]==-1){
            plabelB[0]-=text_box[2];
          } else if(anchor[0]==0){
            plabelB[0]-=0.5*text_box[2];
          }
          plabelB[0]-=padding[3];
          plabelB[1]-=text_box_line1[1]+text_box_line1[3]+padding[0];
          plabelB_WH[0]=text_box[2]+padding[3]+padding[1];
          plabelB_WH[1]=text_box[3]+padding[0]+padding[2];
          
          out.printE("<rect x='%.3g' y='%.3g' width='%.3g' height='%.3g' "
            "id='%s-border' style='%s'",plabelB[0],plabelB[1],plabelB_WH[0],
            plabelB_WH[1],id_.v(),styleT.v());
          MyTSchar* border_radius=svgml.give_property(styleEntity,OP::border_radius);
          if(border_radius){
            double r=atof(border_radius->v());
            out.printE(" rx='%.3g' ry='%.3g'",r,r);
          }
          out.printE("/>\n");
          if(border_strokeList.num()>1){
            dvec4 coords; const char* stroke;
            for(int i=0;i<4;i++){
              coords[0]=plabelB[0]; coords[1]=plabelB[1];
              coords[2]=plabelB[0]+plabelB_WH[0]; coords[3]=plabelB[1]+plabelB_WH[1];
              stroke=border_strokeList[0].v();
              if(i==0){
                coords[3]=plabelB[1];
              } else if(i==1){
                coords[1]=plabelB[1]+plabelB_WH[1];
                if(border_strokeList.num()>=3) stroke=border_strokeList[2].v();
              } else if(i==2){
                coords[2]=plabelB[0];
                if(border_strokeList.num()==4) stroke=border_strokeList[3].v();
                else if(border_strokeList.num()>1) stroke=border_strokeList[1].v();
              } else if(i==3){
                coords[0]=plabelB[0]+plabelB_WH[0];
                if(border_strokeList.num()>1) stroke=border_strokeList[1].v();
              }
              if(strcmp(stroke,"none")==0) continue;
              out.printE("<line x1='%.3g' y1='%.3g' x2='%.3g' y2='%.3g' "
                "id='%s-border-%d' style='%s;stroke:%s;'/>",coords[0],coords[1],coords[2],
                coords[3],id_.v(),i,styleT.v(),stroke);
            }
          }
        } else {
          plabelB=pLabel;
          if(anchor[0]==-1){
            plabelB[0]-=text_box[2];
          } else if(anchor[0]==0){
            plabelB[0]-=0.5*text_box[2];
          }
          plabelB[1]-=text_box[1]+text_box[3];
          plabelB_WH[0]=text_box[2];
          plabelB_WH[1]=text_box[3];
        }
        set_bbox(bbox_,plabelB);
        plabelB+=dvec3(plabelB_WH[0],plabelB_WH[1],0);
        add_to_bbox(bbox_,plabelB);
        
        out.printE("<text x='%.3g' y='%.3g' text-anchor='%s' id='%s' style='%s'>",
          pLabel[0],pLabel[1],text_anchor,id_.v(),style.v());
        svgml.append_tspans(pLabel[0],text,out,font_family.v(),fweight,fstyle,font_size);
        out.printE("</text>\n");
      }
    }
    break;
    case OC::copy:
    {
      Svgml_copy copy_infoL;
      MyTSint entities;
      
      this->give_from_entities(svgml,entities);
      
      MyTSchar* connect_classTS=this->give_property(OP::connect_class);
      if(connect_classTS){
        copy_infoL.connect_class_=*connect_classTS;
      } else {
        connect_classTS=this->give_property(OP::cclass);
        if(connect_classTS){
          copy_infoL.connect_class_=*connect_classTS;
        } else {
          int parent=svgml.give_entityN(id_parent_.v(),id_.v());
          connect_classTS=svgml.entities_[parent].give_property(OP::cclass);
          if(connect_classTS){
            copy_infoL.connect_class_=*connect_classTS;
          } else {
            //throw MyTSchar("necessary a class for copy line='%s'",line_.v());
          }
        }
      }
      MyTSchar* labels=this->give_property(OP::labels);
      if(labels){
        copy_infoL.labels_=*labels;
      }
      MyTSchar* connect=this->give_property(OP::connect);
      if(connect){
        copy_infoL.connect_=*connect;
      }
      copy_infoL.style_=style;
      copy_infoL.styleEntity_=styleEntity;
      copy_infoL.entity_=entity_num;
      
      int number=1;
      MyTSchar* numberTS=this->give_property(OP::number);
      if(numberTS){
        number=atoi(numberTS->v());
      }
      
      if(copy_info){
        copy_infoL.operations_=copy_info->operations_;
      }
      copy_infoL.operations_.set_min_memnum(copy_infoL.operations_.num()+number);
      Svgml_copy_OP& op=copy_infoL.operations_.incr_num();

      MyTSchar* operationTS=this->give_property(OP::operation);
      if(operationTS){
        MyTScharList list;
        string_split_text_sep(operationTS->v(),-1,",",list);
        int pos=string_isin_pos(list[0].v(),Svgml_copy_OPs_g_);
        if(pos==-1){
          throw MyTSchar("unknown operation in copy. line='%s'",line_.v());
        }
        op.operation_=Svgml_copy_OPs(pos);
        if(list.num()>1){
          op.operation_formula_=list[1];
        }
      }
      MyTSvec<dvec3,10> points; int has_delta=0;
      for(int i=0;i<points_.num();i++){
        if(points_[i].ptype_==TP::dp){
          if(i==0 || !is_point(points_[i-1].ptype_)){
            op.delta_=points_[i].point_;
            has_delta=1;
          } else {
            op.deltaList_.incr_num();
            op.deltaList_[end_MTS].point_=points_[i-1].pointG_;
            op.deltaList_[end_MTS].delta_=points_[i].point_;
          }
        } else if(is_point(points_[i].ptype_)){
          points.incr_num()=points_[i].pointG_;
        }
      }
      if(op.operation_formula_.num()){
        op.delta_=dvec3();
        const char* rex="\\A\\s*([-+\\de.]+)[*]P(\\d+)";
        int c=0; const char* mA[3]; int mL[3];
        while(string_regexp(op.operation_formula_.v(),c,-1,rex,mA,mL,3)==1){
          double alpha=atof(mA[1]);
          int p_num=atoi(mA[2]);
          if(p_num<1 || p_num>points.num()){
            throw MyTSchar("operation formula incorrect in copy. line='%s'",line_.v());
          }
          op.delta_+=alpha*points[p_num-1];
          c=mA[0]-op.operation_formula_.v()+mL[0];
        }
        if(string_regexp(op.operation_formula_.v(),c,-1,"\\A\\s*$")==0){
          throw MyTSchar("operation formula incorrect in copy. line='%s'",line_.v());
        }
      } else if(!has_delta && op.deltaList_.num()==0){
        if(op.operation_==CO::symmetry){
          if(points.num()!=2){
            throw MyTSchar("'copy' with symmetry must be defined with two "
              "points. line='%s'",line_.v());
          }
          op.deltaList_.incr_num();
          op.deltaList_[end_MTS].point_=points_[0].pointG_;
          dvec3 t=normalize(points_[1].pointG_-points_[0].pointG_);
          op.deltaList_[end_MTS].delta_=dvec3(t[1],-t[0],0.0);
        } else if(points.num()==2){
          op.delta_=points[1]-points[0];
        } else {
          throw MyTSchar("'copy' must have a delta-point property or two "
            "points. line='%s'",line_.v());
        }
      }
      int numE=svgml.entities_.num();
      int numO=out.num();
      int markers_pos=svgml.markers_pos_;
      for(int i=1;i<=number;i++){
        if(i>1){
          copy_infoL.operations_.incr_num()=op;
        }
        for(int j=0;j<entities.num();j++){
          copy_infoL.entity_from_=entities[j];
          if(svgml.entities_.num()==svgml.entities_.give_memnum()){
            svgml.entities_.set_min_memnum(svgml.entities_.num()*2);
            throw MarkdownException(EXP::try_again);
          }
          svgml.entities_.incr_num();
          svgml.entities_[end_MTS]=svgml.entities_[entities[j]];
          svgml.entities_[end_MTS].give_idTS().print0("%s.__%d__%s",id_.v(),
            i,svgml.entities_[entities[j]].id_.v());
          svgml.entities_[end_MTS].bbox_=dvec4();
          svgml.entities_[end_MTS].is_calculated_=0;
          svgml.entities_[end_MTS].is_dependent_=1;
          int numE_L=svgml.entities_.num();
          try { svgml.entities_[end_MTS].create(j,out,svgml,&copy_infoL); }
          catch(const MarkdownException& exp) {
            UNUSED(exp);
            svgml.entities_.set_num(numE);
            out.set_num(numO+svgml.markers_pos_-markers_pos);
            throw;
          }
          for(int k=numE_L;k<svgml.entities_.num();k++){
            svgml.entities_[k].is_dependent_=1;
            try { svgml.entities_[k].create(k,out,svgml); }
            catch(const MarkdownException& exp) {
              UNUSED(exp);
              svgml.entities_.set_num(numE);
              out.set_num(numO+svgml.markers_pos_-markers_pos);
              throw;
            }
          }
        }
      }
      if(copy_info){
        if(copy_info->init_bbox_==0){
          svgml.entities_[copy_info->entity_].bbox_=bbox_;
          copy_info->init_bbox_=1;
        } else {
          add_to_bbox(svgml.entities_[copy_info->entity_].bbox_,bbox_);
        }
      }
    }
    break;
    case OC::volume:
    {
      MyTSint entities;
      this->give_from_entities(svgml,entities);
      
      if(entities.num()!=2){
        throw MyTSchar("error only allowed two entities. line='%s'",line_.v());
      }
      if(svgml.otype_==OTS::gid){
        for(int i=0;i<4;i++){
          gid_start_numbers_[i]=svgml.gid_numbers_[i]+1;
        }
        SvgmlEntity& e1=svgml.entities_[entities[0]];
        SvgmlEntity& e2=svgml.entities_[entities[1]];
        if(e1.gid_start_numbers_[1]==0 || e2.gid_start_numbers_[1]==0){
          throw MarkdownException(EXP::needs_recalculate);
        }
        MyTSint i_points,lines,surfaces;
        for(int i=0;i<e1.points_.num();i++){
          if(e1.points_[i].gid_numbers_[0]==0 && is_zZ(e1.points_[i].ptype_)==0) continue;
          if(e2.points_.num()<=i){
            throw MyTSchar("entities not compatible. line='%s'",line_.v());
          }
          if(e1.points_[i].gid_numbers_[0]){
            int gid_point1=e1.points_[i].gid_numbers_[0];
            int gid_point2=e2.points_[i].gid_numbers_[0];
            if(i_points.num() && gid_point1==e1.points_[i_points[end_MTS]].gid_numbers_[0]){
              i_points[end_MTS]=i;
              continue;
            }
            int gid_line=svgml.gid_common_line(gid_point1,gid_point2);
            if(gid_line==0){
              MyTSchar group=id_;
              group.regsub(0,"\\.","//");
              out.printE("<a n='create_group' a='-ifnotexists 1 -set_as_default 1 "
                "{Name {%s} IsLayer 1}'/>\n",group.v());
              out.printE("<a n='create_line' a='line {");
              e1.points_[i].output_gid(out,svgml,e1);
              e2.points_[i].output_gid(out,svgml,e2);
              out.printE("}'/>\n");
              gid_line=++svgml.gid_numbers_[1];
              svgml.gid_higher_entities_[0].appendL(gid_point1).append(gid_line);
              svgml.gid_higher_entities_[0].appendL(gid_point2).append(gid_line);
            }
            lines.append(gid_line);
          } else {
            lines.append(lines[0]);
            i_points.append(i_points[0]);
          }
          if(lines.num()>1){
            int gid_surface=svgml.gid_common_surface(lines[end_MTS-1],lines[end_MTS]);
            if(gid_surface==0){
              MyTSchar group=id_;
              group.regsub(0,"\\.","//");
              out.printE("<a n='create_group' a='-ifnotexists 1 -set_as_default 1 "
                "{Name {%s} IsLayer 1}'/>\n",group.v());
              out.printE("<a n='create_surface' a='by_contour {");
              out.printE("%d %d %d %d",e1.points_[i_points[end_MTS]].gid_numbers_[1],
                e2.points_[i_points[end_MTS]].gid_numbers_[1],lines[end_MTS-1],lines[end_MTS]);
              out.printE("}'/>\n");
              gid_surface=++svgml.gid_numbers_[2];
              svgml.gid_higher_entities_[1].appendL(lines[end_MTS-1]).append(gid_surface);
              svgml.gid_higher_entities_[1].appendL(lines[end_MTS]).append(gid_surface);
            }
            surfaces.append(gid_surface);
          }
          if(i_points.num() && e1.points_[i].gid_numbers_[0]==
            e1.points_[i_points[0]].gid_numbers_[0]){
            break;
          }
          i_points.append(i);
        }
        surfaces.append(e1.gid_start_numbers_[2]);
        surfaces.append(e2.gid_start_numbers_[2]);
        
        MyTSchar group=id_;
        group.regsub(0,"\\.","//");
        out.printE("<a n='create_group' a='-ifnotexists 1 -set_as_default 1 "
          "{Name {%s} IsLayer 1}'/>\n",group.v());
        out.printE("<a n='create_volume' a='by_contour {");
        for(int i=0;i<surfaces.num();i++){
          if(i>0) out.printE(" ");
          out.printE("%d",surfaces[i]);
        }
        out.printE("}'/>\n");
        int gid_volume=++svgml.gid_numbers_[3];
        svgml.gid_higher_entities_[2].appendL(lines[end_MTS-1]).append(gid_volume);
        svgml.gid_higher_entities_[2].appendL(lines[end_MTS]).append(gid_volume);
      }
    }
    break;
    case OC::condition: case OC::problemdata:
    {
      MyTSint entities;
      if(svgml.otype_==OTS::gid){
        if(cmd_==OC::condition){
          this->give_from_entities(svgml,entities);
        }
        MyTSchar* name=this->give_property(OP::name);
        if(!name){
          if(cmd_==OC::condition){
            throw MyTSchar("condition needs a property name. line='%s'",line_.v());
          }
        } else {
          if(cmd_==OC::problemdata){
            throw MyTSchar("problemdata cannot have a property name. line='%s'",line_.v());
          }
        }
        MyTSchar* over=this->give_property(OP::over);
        if(over){
          const char* ovlist[]={"point","line","surface","volume",NULL};
          int pos=string_isin_pos(over->v(),ovlist);
          if(pos==-1){
            throw MyTSchar("over must be: point,line,surface,volume. line='%s'",line_.v());
          }
        }
        MyTSchar values_dict; MyTScharList values_list;
        MyTSchar* values=this->give_property(OP::values);
        if(values){
          MyTScharList idsList; char* endptr; const char* mA[2]; int mL[2];
          string_split_text_sep(values->v(),-1,",",idsList);
          for(int i=0;i<idsList.num()-1;i+=2){
            values_list.incr_num()=idsList[i];
            MyTScharList vu;
            vu.incr_num()="v";
              if(idsList[i+1].regexp(0,"^\\s*[-+\\d.]")){
              double d=strtod(idsList[i+1].v(),&endptr);
              vu.incr_num().print0("%g",d);
              if(string_regexp(endptr,0,-1,"^\\s*(\\S+)",mA,mL,2)==1){
                vu.incr_num()="units";
                vu.incr_num().setV(mA[1],mL[1]);
              }
            } else {
              vu.incr_num()=idsList[i+1];
            }
            if(cmd_==OC::condition){
              values_list.incr_num();
              string_create_tcl_list(vu,values_list[end_MTS]);
            } else {
              if(vu.num()==2){
                values_list.incr_num()=vu[1];
              } else {
                vu.clear(2); vu.clear(0);
                values_list.incr_num();
                string_create_tcl_list(vu,values_list[end_MTS]);
              }
            }
          }
        }
        if(cmd_==OC::condition){
          string_quote_xml(*name);
          string_create_tcl_list(values_list,values_dict);
          string_quote_xml(values_dict);
          for(int i=0;i<entities.num();i++){
            MyTSchar group=svgml.entities_[entities[i]].id_;
            group.regsub(0,"\\.","//");
            string_quote_xml(group);
            out.printE("<a n='gid_groups_conds::apply_condition' a='");
            if(over){
              out.printE("-ov %s ",over->v());
            }
            out.printE("{//condition[@n=\"%s\"]} {%s} {%s}'/>\n",name->v(),group.v(),values_dict.v());
          }
        } else {
          for(int i=0;i<values_list.num()-1;i+=2){
            string_quote_xml(values_list[i]);
            string_quote_xml(values_list[i+1]);
            out.printE("<a n='gid_groups_conds::modify_value_nodeXP' a='");
            out.printE("{//value[@n=\"%s\"]} {%s}'/>\n",values_list[i].v(),values_list[i+1].v());
          }        
        }
      }
      // <value n="Solids_e" pn="Solids" v="0" values="0,1"
      // apply_condition -ov point|line|surface|volume xpathCnd group_name values_dict
      // gid_groups_conds::modify_value_nodeXP xpathNode newvalue
    }
    break;
    case OC::svgml: case OC::svgml_alt: case OC::cclass: break;
    default:
    {
      throw MyTSchar("unknown command. line='%s'",line_.v());
    }
    break;
  }
}

int Svgml::gid_common_line(int gid_point1,int gid_point2)
{
  MyTSint6* h1=gid_higher_entities_[0].getL(gid_point1);
  MyTSint6* h2=gid_higher_entities_[0].getL(gid_point2);
  if(!h1 || !h2) return 0;
  for(int i=0;i<h1->num();i++){
    if(h2->isin_pos((*h1)[i])!=-1){
      return (*h1)[i];
    }
  }
  return 0;
}

int Svgml::gid_common_surface(int gid_line1,int gid_line2)
{
  MyTSint6* h1=gid_higher_entities_[1].getL(gid_line1);
  MyTSint6* h2=gid_higher_entities_[1].getL(gid_line2);
  if(!h1 || !h2) return 0;
  for(int i=0;i<h1->num();i++){
    if(h2->isin_pos((*h1)[i])!=-1){
      return (*h1)[i];
    }
  }
  return 0;
}

MyTSchar* SvgmlEntity::give_property(SvgmlProperties prop)
{
  if(properties_.exists(ggclong(prop))){
    return &properties_.getF_L(ggclong(prop)).value_;
  } else {
    return NULL;
  }
}

void SvgmlEntity::remove_property(SvgmlProperties prop)
{
  if(properties_.exists(ggclong(prop))){
    properties_.getF_L(ggclong(prop)).name_=OP::unknown;
    properties_.remove(ggclong(prop));
  }
}

SvgmlPoint* SvgmlEntity::give_point(SvgmlPoints ptype)
{
  for(int i=0;i<points_.num();i++){
    if(points_[i].ptype_==ptype) return &points_[i];
  }
  return NULL;
}

void SvgmlEntity::remove_abbreviations(Svgml& svgml)
{
  int is_abbreviated;
  SvgmlEntity* parent=svgml.give_entity(id_parent_.v(),id_.v(),&is_abbreviated);
  if(!parent) return;
  if(parent->give_idTS().regexp(0,"^(0|__ROOT)$")==0){
    parent->remove_abbreviations(svgml);
  }
  if(is_abbreviated){
    id_parent_=parent->give_idTS();
    id_.print0("%s.%s",id_parent_.v(),id_short_.v());
  }
}

Svgml::Svgml(SvgmlOutputType otype,MKstate* mkstate): otype_(otype),
  mkstate_(mkstate)
{
  if(!Svgml::propNames_) Svgml::propNames_=new Mytextlongtable(SvgmlProperties_g_);
  if(!Svgml::cmdNames_) Svgml::cmdNames_=new Mytextlongtable(SvgmlCommands_g_);
}

SvgmlEntity* Svgml::give_entity(const char* id,const char* idREF,int* is_abbreviated)
{
  int ret=this->give_entityN(id,idREF,is_abbreviated);
  if(ret==-1) return NULL;
  return &entities_[ret];
}

inline int num_common_parents_prefix(const char* id1,const char* id2)
{
  MyTScharList list1,list2;
  string_split_text_sep(id1,-1,".",list1);
  string_split_text_sep(id2,-1,".",list2);
  for(int i=0;i<list1.num();i++){
    if(i>=list2.num() || strcmp(list1[i].v(),list2[i].v())!=0){
      return i;
    }
  }
  return list1.num();
}

int Svgml::give_entityN(const char* id,const char* idREF,int* is_abbreviated)
{
  int ret=-1;
  for(int i=0;i<entities_.num();i++){
    if(strcmp(id,entities_[i].give_id())==0){
      if(is_abbreviated) *is_abbreviated=0;
      return i;
    }
    if(strcmp(id,entities_[i].give_id_short())==0 && 
      entities_[i].give_idTS().regexp(0,"__")==0){
      if(is_abbreviated) *is_abbreviated=1;
      if(ret!=-1){
        int nc1=num_common_parents_prefix(entities_[ret].id_.v(),idREF);
        int nc2=num_common_parents_prefix(entities_[i].id_.v(),idREF);
        if(nc1==nc2){
          throw MyTSchar("Ambiguous reference to '%s'",id);
        } else if(nc1>nc2){
          // ret
        } else {
          ret=i;
        }
      } else {
        ret=i;
      }
    }
  }
  if(ret==-1){
    MyTScharList list;
    string_split_text_sep(id,-1,".",list);
    if(list.num()>1){
      int is_abbreviatedL;
      int retL=this->give_entityN(list[0].v(),idREF,&is_abbreviatedL);
      if(retL!=-1 && is_abbreviatedL){
        list[0]=entities_[retL].id_;
        MyTSchar idTS=string_join(list,".");
        return this->give_entityN(idTS.v(),idREF,is_abbreviated);
      }
    }
  }
  return ret;
}

void Svgml::give_descendants(const char* id,const char* id_avoid,
  MyTSvec<SvgmlEntity*,10>& entities)
{
  size_t n=strlen(id);
  for(int i=0;i<entities_.num();i++){
    if(strncmp(id_avoid,entities_[i].give_id(),strlen(id_avoid))==0) continue;
    if(strlen(entities_[i].give_id())<n+2) continue;
    if(strncmp(id,entities_[i].give_id(),n)!=0) return;
    if(entities_[i].give_id()[n]!='.') continue;
    if(entities_[i].give_idTS().regexp(0,"__")==1) continue;
    entities.append(&entities_[i]);
  }
}

void Svgml::give_descendants(const char* id,const char* id_avoid,
  MyTSint& entities)
{
  size_t n=strlen(id);
  for(int i=0;i<entities_.num();i++){
    if(strncmp(id_avoid,entities_[i].give_id(),strlen(id_avoid))==0) continue;
    if(strlen(entities_[i].give_id())<n+2) continue;
    if(strncmp(id,entities_[i].give_id(),n)!=0) return;
    if(entities_[i].give_id()[n]!='.') continue;
    if(entities_[i].give_idTS().regexp(0,"__")==1) continue;
    entities.append(i);
  }
}

MyTSchar* Svgml::give_property(int entity,SvgmlProperties prop)
{
  if(entity==-1) return NULL;
  return entities_[entity].give_property(prop);
}

void Svgml::init_rdinfo_lineNum(int lineNum,int lineNum_pos)
{
  lineNum_=lineNum; 
  lineNum_pos_=lineNum_pos;
}

void Svgml::give_rdinfo_lineNum(int& lineNum,int& lineNum_pos)
{
  lineNum=lineNum_; 
  lineNum_pos=lineNum_pos_;
}

void Svgml::update_rdinfo_lineNum(MyTSchar& buffer,MyTSchar& out,int start,
  int is_continuation)
{
  for(int i=lineNum_pos_+1;i<start;i++){
    if(buffer[i]=='\n'){
      if(!is_continuation){
        out.printE("\n0 n");
      } else {
        out.printE("\n0 c");
      }
      lineNum_pos_=i;
      lineNum_++;
    }
  }
}

void Svgml::process_rdinfo(MyTSchar& buffer,MyTSchar& out,int start,int end,
  int& lineNum,int& lineNum_pos)
{
  const char* mA[4]; int mL[4];
  const char* name_valueA[2]; int name_valueL[2];
  
  this->init_rdinfo_lineNum(lineNum,lineNum_pos);
  
  int is_continuation=0;
  for(int i=start;i<=end;i++){
    int startL=i;
    int endAL=i;
    while(endAL<end && buffer[endAL]!='\n') endAL++;
    
    const char* rexC="<!-- .* -->|\\A\\s{0,4}#.*";
    const char* rexCont="^\\s*(\\S.*)$";
    const char* rexN="^\\s*([+\\w.*]+)\\s+(?:([+\\w]+)\\s+)?(.*)$";
      
    if(string_regexp(buffer.v(),startL,endAL,rexC,mA,mL,1)==1){
      int c0=mA[0]-buffer.v();
      int c1=mA[0]-buffer.v()+mL[0];
      this->update_rdinfo_lineNum(buffer,out,c0,is_continuation);
      out.printE(" red %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
    } else if(is_continuation && string_regexp(buffer.v(),startL,endAL,rexCont,mA,mL,2)==1){
      int c=mA[1]-buffer.v();
      while(next_property(buffer.v(),c,-1,name_valueA,name_valueL)!=-1){
        int c0=name_valueA[0]-buffer.v();
        int c1=name_valueA[0]-buffer.v()+name_valueL[0];
        this->update_rdinfo_lineNum(buffer,out,c0,is_continuation);
        out.printE(" blue %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
      }
    } else if(string_regexp(buffer.v(),startL,endAL,rexN,mA,mL,4)==1){
      this->update_rdinfo_lineNum(buffer,out,startL,is_continuation);
      int c0=mA[1]-buffer.v();
      int c1=mA[1]-buffer.v()+mL[1];
      out.printE(" green %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
      if(mL[2]>0){
        c0=mA[2]-buffer.v();
        c1=mA[2]-buffer.v()+mL[2];
        out.printE(" magenta %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
      }
      int c=mA[3]-buffer.v();
      while(next_property(buffer.v(),c,-1,name_valueA,name_valueL)!=-1){
        int c0=name_valueA[0]-buffer.v();
        int c1=name_valueA[0]-buffer.v()+name_valueL[0];
        this->update_rdinfo_lineNum(buffer,out,c0,is_continuation);
        out.printE(" blue %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
      }
    } else if(string_regexp(buffer.v(),startL,endAL,"^\\s*(~{3,})",mA,mL,2)==1){
      this->update_rdinfo_lineNum(buffer,out,startL,is_continuation);
      int c0=mA[1]-buffer.v();
      int c1=mA[1]-buffer.v()+mL[1];
      out.printE(" red %d %d",c0-lineNum_pos_-1,c1-lineNum_pos_-1);
    }
    if(string_regexp(buffer.v(),startL,endAL,"\\\\\\Z")==1){
      is_continuation=1;
    } else {
      is_continuation=0;
    }
    i=endAL;
  }
  this->give_rdinfo_lineNum(lineNum,lineNum_pos);
}

static void tabinfo_append_escaped_text(MyTSchar& out,const char* txt,int len)
{
  for(int i=0;i<len;i++){
    if(is_chars(txt[i],"\\*_^~")) out.append('\\');
    out.append(txt[i]);
  }
}

void Svgml::process_tabinfo(MyTSchar& buffer,MyTSchar& out,int start,int end)
{
  const char* mA[4]; int mL[4];
  const char* name_valueA[2]; int name_valueL[2];
    
  int is_continuation=0,last_is_cmd=0;
  for(int i=start;i<=end;i++){
    int startL=i;
    int endAL=i;
    while(endAL<end && buffer[endAL]!='\n') endAL++;
    
// .___           fill:red;
// .__            fill:green;
// ._             fill:magenta;
// .***           fill:blue;
    
    const char* rexC="<!-- .* -->|\\A\\s{0,4}#.*";
    const char* rexCont="^\\s*(\\S.*)$";
    const char* rexN="^\\s*([+\\w.*]+)\\s+(?:([+\\w]+)\\s+)?(.*)$";
      
    if(string_regexp(buffer.v(),startL,endAL,rexC,mA,mL,1)==1){
      int c0=mA[0]-buffer.v();
      out.printE("___");
      tabinfo_append_escaped_text(out,&buffer[c0],mL[0]);
      out.printE("___");
      startL=c0+mL[0];
    } else if(is_continuation && string_regexp(buffer.v(),startL,endAL,rexCont,mA,mL,2)==1){
      int c=mA[1]-buffer.v();
      startL=c;
      out.printE("\t");
      if(last_is_cmd){
        out.printE(" \t");
      }
      while(next_property(buffer.v(),c,endAL,name_valueA,name_valueL)!=-1){
        int c0=name_valueA[0]-buffer.v();
        tabinfo_append_escaped_text(out,&buffer[startL],c0-startL);
        out.printE("***");
        tabinfo_append_escaped_text(out,&buffer[c0],name_valueL[0]);
        out.printE("***");
        startL=c0+name_valueL[0];
      }
    } else if(string_regexp(buffer.v(),startL,endAL,rexN,mA,mL,4)==1){
      int c0=mA[1]-buffer.v();
      out.printE("__");
      tabinfo_append_escaped_text(out,&buffer[c0],mL[1]);
      out.printE("__");
      out.printE("\t");
      if(mL[2]>0){
        c0=mA[2]-buffer.v();
        out.printE("_");
        tabinfo_append_escaped_text(out,&buffer[c0],mL[2]);
        out.printE("_");
        out.printE("\t");
        last_is_cmd=1;
      } else {
        last_is_cmd=0; 
      }
      int c=mA[3]-buffer.v();
      startL=c;
      while(next_property(buffer.v(),c,endAL,name_valueA,name_valueL)!=-1){
        int c0=name_valueA[0]-buffer.v();
        tabinfo_append_escaped_text(out,&buffer[startL],c0-startL);
        out.printE("***");
        tabinfo_append_escaped_text(out,&buffer[c0],name_valueL[0]);
        out.printE("***");
        startL=c0+name_valueL[0];
      }
    }
    tabinfo_append_escaped_text(out,&buffer[startL],endAL-startL+1);
    if(string_regexp(buffer.v(),startL,endAL,"\\\\\\r?\\Z")==1){
      is_continuation=1;
    } else {
      is_continuation=0;
    }
    i=endAL;
  }
}

void Svgml::append_tspans(double x,MyTSchar& label,MyTSchar& out,const char* fontname,
  FT_FontWeight fweight,FT_FontStyle fstyle,double font_size)
{
  label.regsub(0,"[ ]+"," ");
  label.regsub(0,"[ ]*(\n|\\\\n)[ ]*","\n");
  label.regsub(0,"[ ]*(\t|\\\\t)[ ]*","\t");
  
  MyTSvec<SvgmlSplitTextC,3> splits;
  split_text(label,splits);
  
  int tab_number=0; MyTSdouble tab_widths;
  dvec4 text_box; double width=0;
  for(int i=0;i<splits.num();i++){
    if(splits[i].has_tab() || splits[i].has_newline()){
      if(!splits[i].has_newline()){
        if(tab_widths.num()<=tab_number) tab_widths.set_num(tab_number+1);
        if(width>tab_widths[tab_number]){
          tab_widths[tab_number]=width;
        }
      }
      width=0;
      if(splits[i].has_newline()) tab_number=0;
      else tab_number++;
    }
    double font_sizeL=font_size;
    FT_FontWeight fweightL=fweight;
    FT_FontStyle fstyleL=fstyle;
    
    for(int j=0;j<splits[i].types_.num();j++){
      if(splits[i].types_[j]==ST::none || splits[i].types_[j]==ST::tab || 
        splits[i].types_[j]==ST::newline){
        // nothing
      } else if(splits[i].types_[j]==ST::sub){
        font_sizeL*=0.65;
      } else if(splits[i].types_[j]==ST::sup){
        font_sizeL*=0.65;
      } else {
        MyTSchar styleName(".%s",SvgmlSplitText_g_[int(splits[i].types_[j])]);
        if(entities_.exists(styleName.v())){
          int styleEntity=entities_.Mytextlongtable::get(styleName.v());
          MyTSchar* font_weightP=this->give_property(styleEntity,OP::font_weight);
          const char* boldList[]={"bold","700",NULL};
          if(font_weightP && string_isin_pos(font_weightP->v(),boldList)!=-1){
            fweightL=FW::bold;
          } else {
            fweightL=FW::normal;
          }
          MyTSchar* font_styleP=this->give_property(styleEntity,OP::font_style);
          if(font_styleP && strcmp(font_styleP->v(),"italic")==0){
            fstyleL=FS::italic;
          } else if(font_styleP && strcmp(font_styleP->v(),"oblique")==0){
            fstyleL=FS::oblique;
          } else {
            fstyleL=FS::normal;
          }
        } else {
          switch(splits[i].types_[j]){
            case ST::asterisk1: case ST::underline1: fstyleL=FS::italic; break;
            case ST::asterisk2: case ST::underline2: fweightL=FW::bold; break;
            case ST::asterisk3: case ST::underline3: fweightL=FW::bold; fstyleL=FS::italic; break;  
          }
        }
      }
    }
    font_measure_g_->measure_text_line(splits[i].text_.v(),fontname,fweightL,fstyleL,
      font_sizeL,text_box);
    width+=text_box[2]+0.6*font_size;
  }

  tab_number=0;
  for(int i=0;i<splits.num();i++){
    out.printE("<tspan");
    MyTSchar style;
    for(int j=0;j<splits[i].types_.num();j++){
      if(splits[i].types_[j]==ST::none){
        // nothing
      } else if(splits[i].types_[j]==ST::tab){
        double xL=x;
        for(int k=0;k<=tab_number;k++){
          xL+=tab_widths[k];
        }
        out.printE(" x='%.3g'",xL);
        tab_number++;
      } else if(splits[i].types_[j]==ST::newline){
        out.printE(" x='%.3g' dy='1.2em'",x);
        tab_number=0;
      } else if(splits[i].types_[j]==ST::sub){
        style.printE("font-size:65%%;baseline-shift:sub;");
      } else if(splits[i].types_[j]==ST::sup){
        style.printE("font-size:65%%;baseline-shift:super;");
      } else {
        MyTSchar styleName(".%s",SvgmlSplitText_g_[int(splits[i].types_[j])]);
        if(entities_.exists(styleName.v())){
          style.printE("%s",entities_.getF_H(styleName.v()).contents_.v());
        } else {
          switch(splits[i].types_[j]){
            case ST::asterisk1: case ST::underline1: style.printE("font-style:italic;"); break;
            case ST::asterisk2: case ST::underline2: style.printE("font-weight:bold;"); break;
            case ST::asterisk3: case ST::underline3: style.printE("font-weight:bold;font-style:italic;"); break;  
          }
        }
      }
    }
    if(style.num()){
      out.printE(" style='%s'",style.v());
    }
    out.printE(" xml:space='preserve'>%s</tspan>",string_quote_xml(splits[i].text_,0));
  }
}

void Svgml::measure_tspans(MyTSchar& label,const char* fontname,
  FT_FontWeight fweight,FT_FontStyle fstyle,double font_size,
  dvec4& boxG,dvec4& boxG_line1)
{
  double font_sizeL;
  
  label.regsub(0,"[ ]+"," ");
  label.regsub(0,"[ ]*(\n|\\\\n)[ ]*","\n");
  label.regsub(0,"[ ]*(\t|\\\\t)[ ]*","\t");
  
  MyTSvec<SvgmlSplitTextC,3> splits;
  split_text(label,splits);
  
  int tab_number=0; MyTSdouble tab_widths;
  dvec4 text_box; double width=0;
  for(int i=0;i<splits.num();i++){
    if(splits[i].has_tab() || splits[i].has_newline()){
      if(!splits[i].has_newline()){
        if(tab_widths.num()<=tab_number) tab_widths.set_num(tab_number+1);
        if(width>tab_widths[tab_number]){
          tab_widths[tab_number]=width;
        }
      }
      width=0;
      if(splits[i].has_newline()) tab_number=0;
      else tab_number++;
    }
    double font_sizeL=font_size;
    FT_FontWeight fweightL=fweight;
    FT_FontStyle fstyleL=fstyle;
    
    for(int j=0;j<splits[i].types_.num();j++){
      if(splits[i].types_[j]==ST::none || splits[i].types_[j]==ST::tab ||
        splits[i].types_[j]==ST::newline){
        // nothing
      } else if(splits[i].types_[j]==ST::sub){
        font_sizeL*=0.65;
      } else if(splits[i].types_[j]==ST::sup){
        font_sizeL*=0.65;
      } else {
        MyTSchar styleName(".%s",SvgmlSplitText_g_[int(splits[i].types_[j])]);
        if(entities_.exists(styleName.v())){
          int styleEntity=entities_.Mytextlongtable::get(styleName.v());
          MyTSchar* font_weightP=this->give_property(styleEntity,OP::font_weight);
          const char* boldList[]={"bold","700",NULL};
          if(font_weightP && string_isin_pos(font_weightP->v(),boldList)!=-1){
            fweightL=FW::bold;
          } else {
            fweightL=FW::normal;
          }
          MyTSchar* font_styleP=this->give_property(styleEntity,OP::font_style);
          if(font_styleP && strcmp(font_styleP->v(),"italic")==0){
            fstyleL=FS::italic;
          } else if(font_styleP && strcmp(font_styleP->v(),"oblique")==0){
            fstyleL=FS::oblique;
          } else {
            fstyleL=FS::normal;
          }
        } else {
          switch(splits[i].types_[j]){
            case ST::asterisk1: case ST::underline1: fstyleL=FS::italic; break;
            case ST::asterisk2: case ST::underline2: fweightL=FW::bold; break;
            case ST::asterisk3: case ST::underline3: fweightL=FW::bold; fstyleL=FS::italic; break;  
          }
        }
      }
    }
    font_measure_g_->measure_text_line(splits[i].text_.v(),fontname,fweightL,fstyleL,
      font_sizeL,text_box);
    width+=text_box[2]+0.6*font_size;
  }

  dvec4 box_line;
  boxG=boxG_line1=dvec4();
  
  tab_number=0; int iline=0;
  for(int i=0;i<splits.num();i++){
    if(i==splits.num()-1 && splits[i].text_.regexp(0,"^\\s*$")) break;
    font_sizeL=font_size;
    FT_FontWeight fweightL=fweight;
    FT_FontStyle fstyleL=fstyle;
    
    for(int j=0;j<splits[i].types_.num();j++){
      if(splits[i].types_[j]==ST::none){
        // nothing
      } else if(splits[i].types_[j]==ST::tab){
        double xL=0;
        for(int k=0;k<=tab_number;k++){
          xL+=tab_widths[k];
        }
        box_line[2]=xL;
        tab_number++;
      } else if(splits[i].types_[j]==ST::newline){
        if(box_line[2]>boxG[2]){
          boxG[2]=box_line[2];
        }
        if(1.2*font_size>box_line[3]){
          boxG[3]+=1.2*font_size;
        } else {
          boxG[3]+=box_line[3];
        }
        if(iline==0){
          boxG_line1=box_line;
        }
        box_line=dvec4();
        tab_number=0;
        iline++;
      } else if(splits[i].types_[j]==ST::sub){
        font_sizeL=0.65*font_size;
      } else if(splits[i].types_[j]==ST::sup){
        font_sizeL=0.65*font_size;
      } else {
        MyTSchar styleName(".%s",SvgmlSplitText_g_[int(splits[i].types_[j])]);
        if(entities_.exists(styleName.v())){
          int styleEntity=entities_.Mytextlongtable::get(styleName.v());
          MyTSchar* font_weightP=this->give_property(styleEntity,OP::font_weight);
          const char* boldList[]={"bold","700",NULL};
          if(font_weightP && string_isin_pos(font_weightP->v(),boldList)!=-1){
            fweightL=FW::bold;
          } else {
            fweightL=FW::normal;
          }
          MyTSchar* font_styleP=this->give_property(styleEntity,OP::font_style);
          if(font_styleP && strcmp(font_styleP->v(),"italic")==0){
            fstyleL=FS::italic;
          } else if(font_styleP && strcmp(font_styleP->v(),"oblique")==0){
            fstyleL=FS::oblique;
          } else {
            fstyleL=FS::normal;
          }
        } else {
          switch(splits[i].types_[j]){
            case ST::asterisk1: case ST::underline1: fstyleL=FS::italic; break;
            case ST::asterisk2: case ST::underline2: fweightL=FW::bold; break;
            case ST::asterisk3: case ST::underline3: fweightL=FW::bold; fstyleL=FS::italic; break;  
          }
        }
      }
    }
    font_measure_g_->measure_text_line(splits[i].text_.v(),fontname,fweightL,fstyleL,
      font_sizeL,text_box);
    box_line[2]+=text_box[2];
    if(text_box[1]<box_line[1]) box_line[1]=text_box[1];
    if(text_box[1]+text_box[3]>box_line[1]+box_line[3]){
      box_line[3]=text_box[1]+text_box[3]-box_line[1];
    }
  }
  if(box_line[2]>boxG[2]){
    boxG[2]=box_line[2];
  }
  boxG[1]=box_line[1];
  boxG[3]+=box_line[3];
  if(iline==0){
    boxG_line1=box_line;
  }
}

void Svgml::parse_data(MyTSchar& buffer,int start,int end,const char* parent)
{
  const char* mA[4]; int mL[4];
  const char* name_valueA[2]; int name_valueL[2];
  MyTScharList list;
  MyTSchar mtsA[2];
  MyTSint restore_backslashes,restore_newline;
  
  int entities0=entities_.num();
  
  for(int i=start;i<=end;i++){
    int startL=i;
    int endAL=i+1;
    while(endAL<=end){
      while(endAL<=end && buffer[endAL]!='\n') endAL++;
      if(string_regexp(buffer.v(),startL,endAL,"(\\\\)\\s*\\Z",mA,mL,2)==1){
        int c=mA[1]-buffer.v();
        buffer[c]=' ';
        restore_backslashes.append(c);
        buffer[endAL]=' ';
        restore_newline.append(endAL);
        endAL++;
      } else {
        break;
      }
    }
    
    const char* rex_comments="\\A\\s*<!-- .* -->|\\A\\s{0,4}#.*";
    const char* rex_svgml="\\A\\s*\\+svgml(\\S+)\\s+(.*)";
    const char* rex_alias="\\A\\s*\\+alias\\s+(\\S.*)";
    const char* rex_variables="\\A\\s*\\+variables\\s+(\\S.*)";
    const char* rex_contents="\\A\\s*(\\w\\S*)\\s+(\\w+)\\s+(\\S.*)";
    const char* rex_class="\\A\\s*(\\.\\S+)\\s+(\\S.*)";
    const char* rex_end_space="\\A\\s*\\Z";

    if(string_regexp(buffer.v(),startL,endAL,rex_comments,mA,mL,1)==1){
      
//################################################################################
//    comments
//################################################################################

      i=endAL;
      continue;
    } else if(string_regexp(buffer.v(),startL,endAL,rex_svgml,mA,mL,3)==1){

//################################################################################
//    svgml
//################################################################################

      if(!parent){
        entities_.incr_num().set("0",-1,OC::svgml,mA[2],mL[2],&buffer[start],endAL-start);
        entities_.getF_H(entities_.num()-1,entities_[end_MTS].give_id());
        version_.setV(mA[1],mL[1]);
        MyTSchar* p=entities_[end_MTS].give_property(OP::width);
        if(!p){
          throw MyTSchar("svgml has no property 'width' in line '%s'",
            entities_[end_MTS].give_line());
        }
        width_=atof(p->v());
        p=entities_[end_MTS].give_property(OP::height);
        if(!p){
          height_=width_;
        } else if(p->regexp(0,"^([\\d.]+)%$",mtsA,2)==1){
          height_=atof(mtsA[1].v())*width_/100.0;
        } else {
          height_=atof(p->v());
        }
        
        entities_[end_MTS].bbox_={0,0,width_,height_};
        
        entities_.incr_num().set("__ROOT",-1,OC::svgml_alt,"",-1,"",-1);
        entities_.getF_H(entities_.num()-1,entities_[end_MTS].give_id());
        entities_[end_MTS].bbox_={0,0,100,100};
      }
    } else if(string_regexp(buffer.v(),startL,endAL,rex_alias,mA,mL,2)==1){

//################################################################################
//    alias
//################################################################################
      
      int c=mA[1]-buffer.v();
      while(next_property(buffer.v(),c,-1,name_valueA,name_valueL)!=-1){
        mtsA[0].setV(name_valueA[0],name_valueL[0]);
        mtsA[1].setV(name_valueA[1],name_valueL[1]);
        if(!propNames_->exists(mtsA[0].v())){
          mtsA[1].setV(&buffer[startL],endAL-startL);
          throw MyTSchar("alias to non-existant property '%s' in line '%s'",
            mtsA[0].v(),mtsA[1].v());
        }
        SvgmlProperties prop=SvgmlProperties(propNames_->get(mtsA[0].v()));
        propNames_->set(mtsA[1].v(),ggclong(prop));
      }
    } else if(string_regexp(buffer.v(),startL,endAL,rex_variables,mA,mL,2)==1){
      
//################################################################################
//    variables
//################################################################################
      
      int c=mA[1]-buffer.v();
      while(next_property(buffer.v(),c,-1,name_valueA,name_valueL)!=-1){
        mtsA[0].setV(name_valueA[0],name_valueL[0]);
        int append=0;
        if(mtsA[0][0]=='+'){
          mtsA[0].clear(0);
          append=1;
        }
        mtsA[1].setV(name_valueA[1],name_valueL[1]);
        if(append && variables_.exists(mtsA[0].v())){
          const char* v0=variables_.get(mtsA[0].v());
          mtsA[1].insertV(0,v0,-1);
        }
        variables_.set(mtsA[0].v(),mtsA[1].v());
      }
    } else if(string_regexp(buffer.v(),startL,endAL,rex_contents,mA,mL,4)==1){
      
//################################################################################
//    contents
//################################################################################
      
      MyTSchar id;
      if(parent) id.print0("%s.",parent);
      id.appendV(mA[1],mL[1]);
      if(entities_.exists(id.v())){
        mtsA[1].setV(&buffer[startL],endAL-startL);
        throw MyTSchar("repeated id '%s' line='%s'",mtsA[0].v(),mtsA[1].v());
      }
      mtsA[1].setV(mA[2],mL[2]);
      if(!Svgml::cmdNames_->exists(mtsA[1].v())){
        mtsA[1].setV(&buffer[startL],endAL-startL);
        throw MyTSchar("unknown command '%s' line='%s'",mtsA[1].v(),mtsA[0].v());
      }
      SvgmlCommands cmd=(SvgmlCommands) Svgml::cmdNames_->get(mtsA[1].v());
      entities_.incr_num().set(id.v(),id.num(),cmd,mA[3],mL[3],
        &buffer[startL],endAL-startL);
      entities_.getF_H(entities_.num()-1,entities_[end_MTS].give_id());
      if(!entities_.exists(entities_[end_MTS].give_id_short())){
        entities_.getF_H(entities_.num()-1,entities_[end_MTS].give_id_short());
      }
    } else if(string_regexp(buffer.v(),startL,endAL,rex_class,mA,mL,3)==1){
    
//################################################################################
//    class
//################################################################################

      MyTSchar cclass;
      if(parent) cclass.print0(".%s",parent);
      cclass.appendV(mA[1],mL[1]);
      if(entities_.exists(cclass.v())){
        mtsA[1].setV(&buffer[startL],endAL-startL);
        throw MyTSchar("repeated id '%s' int class line='%s'",cclass.v(),mtsA[1].v());
      }
      entities_.incr_num().set(cclass.v(),cclass.num(),OC::cclass,
        mA[2],mL[2],&buffer[startL],endAL-startL);
      entities_.getF_H(entities_.num()-1,entities_[end_MTS].give_id());
    } else if(string_regexp(buffer.v(),startL,endAL,rex_end_space,mA,mL,0)==0){
      mtsA[1].setV(&buffer[startL],endAL-startL);
      throw MyTSchar("unknown line '%s'",mtsA[1].v());
    }
    i=endAL;
  }
    
//################################################################################
//    abbreviated names to names
//################################################################################
  
  for(int i=entities0;i<entities_.num();i++){
    entities_[i].remove_abbreviations(*this);
  }
  
//################################################################################
//    change class when there is parent
//################################################################################
  
  if(parent){
    for(int i=entities0;i<entities_.num();i++){
      MyTSchar* cclass=entities_[i].give_property(OP::cclass);
      if(cclass){
        MyTSchar cclassPrev=*cclass;
        cclass->print0("%s.%s",parent,cclassPrev.v());
      }
      MyTSchar* connect_class=entities_[i].give_property(OP::connect_class);
      if(connect_class){
        MyTSchar connect_classPrev=*connect_class;
        connect_class->print0("%s.%s",parent,connect_classPrev.v());
      }
    }
  }
    
//################################################################################
//    substitute variables
//################################################################################
  
  MyTScharList errorMessages;
  for(int i=entities0;i<entities_.num();i++){
    for(int j=0;j<entities_[i].properties_.num();j++){
      if(entities_[i].properties_[j].value_.num()==0) continue;
      SvgmlProperties name=entities_[i].properties_[j].name_;
      MyTSchar& value=entities_[i].properties_[j].value_;
      if(!is_point_stype(name) && value[0]==':'){
        value.regexp(0,":(.*)$",mtsA,2);
        if(variables_.exists(mtsA[1].v())){
          value.setV(variables_.get(mtsA[1].v()),-1);
          continue;
        }
        MyTSchar varname,valuePrev=value;
        value.clear();
        int found=0,c=1; const char* mA[3]; int mL[3];
        while(string_regexp(valuePrev.v(),c,-1,"\\A([^:]*):([^:]+):",mA,mL,3)==1){
          value.appendV(mA[1],mL[1]);
          varname.setV(mA[2],mL[2]);
          if(!variables_.exists(varname.v())){
            errorMessages.incr_num().print0("unknown variable '%s' in line '%s'",
              varname.v(),entities_[i].line_.v());
            continue;
          }
          value.appendV(variables_.get(varname.v()),-1);
          found=1;
          c=mA[0]-valuePrev.v()+mL[0];
        }
        if(c<valuePrev.num()){
          value.appendV(&valuePrev[c],-1);
        }
        if(found) continue;
        
        int iblock;
        if(mkstate_ && mkstate_->give_by_id(mtsA[1].v())){
          iblock=mkstate_->give_by_id(mtsA[1].v())->ibox_;
          int c0=mkstate_->blocks_[iblock].pos_[0];
          int c1=mkstate_->blocks_[iblock].posNoBlank_[0]-1;
          int start=mkstate_->blocks_[iblock].posNoBlank_[0];
          int end=mkstate_->blocks_[iblock].posNoBlank_[1];
          if(string_regexp(mkstate_->buffer_->v(),c0,c1,"svgml")==1){
            if(entities_[i].cmd_==OC::image){
              this->parse_data(*mkstate_->buffer_,start,end,entities_[i].id_.v());
              value.clear();
            } else if(name==OP::text){
              value.clear();
              this->process_tabinfo(*mkstate_->buffer_,value,start,end);
            } else {
              value.setV(&mkstate_->buffer_->v()[start],end-start+1);
            }
          } else {
            value.setV(&mkstate_->buffer_->v()[start],end-start+1);
          }
        } else {
          errorMessages.incr_num().print0("unknown variable '%s' in line '%s'",
            mtsA[1].v(),entities_[i].line_.v());
        }
      }
    }
  }
  if(errorMessages.num()){
    throw string_join(errorMessages,"\n");
  }
  
//################################################################################
//    check viewBox
//################################################################################
  
  for(int i=entities0;i<entities_.num();i++){
    if(entities_[i].cmd_!=OC::svgml) continue;
    MyTSchar* viewBox=entities_[i].give_property(OP::viewBox);
    if(otype_==OTS::gid){
      entities_[i].bbox_={0,0,100,100};
    } else if(viewBox){
      MyTScharList list;
      string_split_text_sep(viewBox->v(),-1,",",list);
      if(list.num()!=4){
        throw MyTSchar("property viewBox needs 4 comma separated values in line '%s'",
          entities_[i].give_line());
      }
      double value[4];
      for(int j=0;j<4;j++){
        if(list[j].regexp(0,":")){
          value[j]=evaluate_expression(list[j].v(),entities_[i].give_line());
        } else {
          value[j]=atof(list[j].v());
        }
      }
      MyTSchar* p=entities_[i].give_property(OP::height);
      if(!p){
        height_=width_*value[3]/value[2];
        entities_[i].bbox_={0,0,width_,height_};
      }
      int reverse_y=0;
      MyTSchar* reverse_y_svg=entities_[i].give_property(OP::reverse_y_svg);
      if(reverse_y_svg && strcmp(reverse_y_svg->v(),"1")==0){
        reverse_y=1;
      }
      for(int j=0;j<2;j++){
        if(j==0 || reverse_y==0){
          double delta=entities_[i].bbox_[j+2]/value[j+2]*100.0;
          entities_[i].bbox_[j]=-value[j]*delta/100.0;
          entities_[i].bbox_[j+2]=delta;
        } else {
          double delta=-1.0*entities_[i].bbox_[j+2]/value[j+2]*100.0;
          entities_[i].bbox_[j]=-(value[j]+value[j+2])*delta/100.0;
          entities_[i].bbox_[j+2]=delta;
        }
      }
    }
  }
  
//################################################################################
//    reorder if parent
//################################################################################
  
  if(parent){
    MyTSvecH<SvgmlEntity,100> entitiesTMP;
    int pos=entities_.Mytextlongtable::get(parent);
    for(int i=entities0;i<entities_.num();i++){
      entities_.remove(entities_[i].id_.v());
      entitiesTMP.incr_num()=entities_[i];
    }
    entities_.set_num(entities0);
    for(int i=0;i<entitiesTMP.num();i++){
      entities_.insert_H(++pos,entitiesTMP[i].id_.v())=entitiesTMP[i];
    }
  }
  
//################################################################################
//    restore
//################################################################################
  
  for(int i=0;i<restore_backslashes.num();i++){
    buffer[restore_backslashes[i]]='\\';
  }
  for(int i=0;i<restore_newline.num();i++){
    buffer[restore_newline[i]]='\n';
  }
}

void Svgml::give_write_marker_id(MyTSchar& marker,const char* stroke,MyTSchar& out)
{
  MyTSchar id;
  
  const char* xmlTriangleInL=
    "<marker orient='auto' refY='0.0' refX='-4.5' id='%s' style='overflow:visible'>\n"
    "<path d='M 4.5,0.0 L -2.3,4.0 L -2.3,-4.0 L 4.5,0.0 z' "
    "style='fill:%s;stroke:none;' transform='scale(-1.0)'/>\n"
    "</marker>\n";
  const char* xmlTriangleOutL=
      "<marker orient='auto' refY='0.0' refX='4.5' id='%s' style='overflow:visible'>\n"
      "<path d='M 4.5,0.0 L -2.3,4.0 L -2.3,-4.0 L 4.5,0.0 z' "
      "style='fill:%s;stroke:none;'/>\n"
      "</marker>\n";
  const char* xmlCircle=
      "<marker orient='auto' refY='0.0' refX='0.0' id='%s' style='overflow:visible'>\n"
      "<circle cx='0.0' cy='0' r='1.5' "
      "style='fill:%s;stroke:none;'/>\n"
      "</marker>\n";
  
  MyTSchar mATS[2],outL;
  if(marker.regexp(0,"^url\\(#(circle|TriangleInL|TriangleOutL)\\)$",mATS,2)==0) return;
  if(strcmp(stroke,"black")==0){
    id.print0("%s",mATS[1].v());
  } else {
    id.print0("%s_%s",mATS[1].v(),stroke);
    marker.print0("url(#%s)",id.v());
  }
  if(!markers_ids_.exists(id.v())){
    if(strcmp(mATS[1].v(),"TriangleInL")==0){
      outL.printE(xmlTriangleInL,id.v(),stroke);
    } else if(strcmp(mATS[1].v(),"TriangleOutL")==0){
      outL.printE(xmlTriangleOutL,id.v(),stroke);
    } else {
      outL.printE(xmlCircle,id.v(),stroke);
    }
    out.insertV(markers_pos_,outL.v(),outL.num());
    markers_pos_+=outL.num();
    markers_ids_.set(id.v(),"");
  }
}

void Svgml::process(MyTSchar& buffer,MyTSchar& out,int start,int end)
{
  MyTSchar mtsA[2];
  MyTScharList list;
  
  this->parse_data(buffer,start,end);
  
//################################################################################
//    header
//################################################################################
    
  if(!entities_.exists("0")){
    throw MyTSchar("there is no header 'svgml'");
  }
  
  if(otype_==OTS::gid){
    const char* xmlH="<?xml version='1.0' encoding='UTF-8' standalone='no'?>\n"
      "<gidpost_batch version='1.0'>\n"
      "<!--created with svgml-RamDebugger <http://www.compassis.com/ramdebugger>-->\n";
    out.printE(xmlH);
  } else {
    const char* xmlH="<?xml version='1.0' encoding='UTF-8' standalone='no'?>\n"
      "<svg xmlns='http://www.w3.org/2000/svg' "
      "xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' "
      "width='%.3g' height='%.3g'>\n"
      "<!--created with svgml-RamDebugger <http://www.compassis.com/ramdebugger>-->\n"
      "<defs>\n";
    out.printE(xmlH,width_,height_);
    
    const char* font="Montserrat:400,400i,700,700i";
    out.printE("<style type='text/css'>\n"
      "@import url('https://fonts.googleapis.com/css?family=%s&amp;display=swap');\n"
      "line,path,circle,rect { fill:green; stroke: orange; stroke-width: 3px; }\n"
      "text { fill:black; stroke:none; font-family: Montserrat; font-size: 12px; }\n"
      "</style>\n",font);
            
    const char* xmlFilters=
      "<filter id='shadow' x='-20%' y='-20%' width='140%' height='140%'>\n"
      "<feGaussianBlur stdDeviation='2 2' result='shadow'/>\n"
      "<feOffset dx='6' dy='6'/>\n"
      "</filter>\n"
      
      "<filter id='glow' x='-30%' y='-30%' width='160%' height='160%'>\n"
      "<feGaussianBlur stdDeviation='10 10' result='glow'/>\n"
      "<feMerge>\n"
      "<feMergeNode in='glow'/>\n"
      "<feMergeNode in='glow'/>\n"
      "<feMergeNode in='glow'/>\n"
      "</feMerge>\n"
      "</filter>\n";
    out.printE(xmlFilters);
    
//################################################################################
//    radial_gradient
//################################################################################
    
    int radial_gradient=1;
    for(int i=0;i<entities_.num();i++){
      if(entities_[i].properties_.exists(ggclong(OP::fill))){
        MyTSchar& v=entities_[i].properties_.getF_L(ggclong(OP::fill)).value_;
        if(v.regexp(0,"radial-gradient\\((.*)\\)",mtsA,2)==0) continue;
        string_split_text_sep(v.v(),-1,",",list);
        MyTSchar id("radial_gradient%d",radial_gradient);
        out.printE(
          "<radialGradient id='%s' cx='50%' cy='50%' r='50%' fx='50%' fy='50%'>\n"
          "<stop offset='0%' style='stop-color:%s;stop-opacity:0' />\n"
          "<stop offset='100%' style='stop-color:%s;stop-opacity:1' />\n"
          "</radialGradient>\n",id.v(),list[0].v(),list[1].v());
        v.print0("url(#%s)",id.v());
        entities_[i].update_contents_from_properties();
        radial_gradient++;
      }
    }
    
//################################################################################
//    markers
//################################################################################
    
    markers_pos_=out.num();
    MyTSchar marker("url(#TriangleInL)");
    // it should be "context-stroke" instead of black but browsers do not support it
    this->give_write_marker_id(marker,"black",out);
    marker.print0("url(#TriangleOutL)");
    this->give_write_marker_id(marker,"black",out);
    marker.print0("url(#circle)");
    this->give_write_marker_id(marker,"black",out);
    
    for(int i=0;i<entities_.num();i++){
      for(ggclong j=ggclong(OP::marker_start);j<=ggclong(OP::marker_end);j++){
        if(entities_[i].properties_.exists(j)){
          MyTSchar& marker=entities_[i].properties_.getF_L(j).value_;
          SvgmlProperty* stroke=entities_[i].properties_.getL(ggclong(OP::stroke));
          if(!stroke || strcmp(stroke->value_.v(),"black")==0 || strcmp(stroke->value_.v(),"#000000")==0){
            continue;
          }
          this->give_write_marker_id(marker,stroke->value_.v(),out);
          entities_[i].update_contents_from_properties();
        }
      }
    }
    
//################################################################################
//    end defs
//################################################################################
    
    out.printE("</defs>\n");
  }
  
//################################################################################
//    loop on entities. The tries are here to solve dependencies of dependencies
//################################################################################
  
  int markers_pos=markers_pos_;
  int num=out.num();
  for(int i_try=0;i_try<10;i_try++){
    int needs_recalculate=0;
    for(int i=0;i<entities_.num();i++){
      if(entities_[i].is_dependent_) continue;
      int markers_posL=markers_pos_;
      int numL=out.num();
      try { entities_[i].create(i,out,*this); }
      catch(const MarkdownException& exp) {
        entities_[i].points_.clear();
        entities_[i].is_calculated_=0;
        if(exp.etype_==EXP::try_again){
          out.set_num(numL+markers_pos_-markers_posL);
          i--;
          continue;
        } else {
          needs_recalculate=1;
        }
      }
    }
    if(!needs_recalculate){
      break;
    } else {
      out.set_num(num+markers_pos_-markers_pos);
    }
  }
  
  if(otype_==OTS::gid){
    if(gid_fileName_.num()){
      out.printE("<a n='save_model' a='%s'/>",gid_fileName_.v());
    }
    out.printE("</gidpost_batch>\n");
  } else {
    out.printE("</svg>\n");
  }
}

void svgml_process(SvgmlOutputType otype,MyTSchar& buffer,MyTSchar& out,
  int start,int end,int& lineNum,int& lineNum_pos,const char* gid_fileName,
  MKstate* mkstate)
{
  Svgml svgml(otype,mkstate);
  
  if(gid_fileName){
    svgml.gid_fileName_=gid_fileName;
  }
  if(otype==OTS::rdinfo){
    svgml.process_rdinfo(buffer,out,start,end,lineNum,lineNum_pos);
  } else if(otype==OTS::tabinfo){
    svgml.process_tabinfo(buffer,out,start,end);
  } else {
    svgml.process(buffer,out,start,end);
  }
}

//################################################################################
//    Initial functions: markdown_evaluate, main, Markdown_evaluate, Markdown_Init
//################################################################################

static void markdown_evaluate(MarkdownOutputType otype,MyTSchar& buffer,
  MyTSchar& out,MyTScharList* extensions=NULL)
{
  MKstate mkstate(otype);
  if(extensions) mkstate.set_extensions(*extensions);
  mkstate.process_markdown(buffer);
  
  mkstate.output_markdown_start(buffer,out);
  
#ifndef NDEBUG
  if(buffer.num() && otype==OT::html){
    MyTSchar deb;
    mkstate.blocks_[0].print_yaml(0,mkstate.blocks_,buffer,deb);
    FILE* dout=fopen("kk.yaml","wb");
    fprintf(dout,"---\n");
    fprintf(dout,"%s",deb.v());
    fprintf(dout,"---\n");
    fclose(dout);
    
//     mkstate.blocks_[0].nprint(0,mkstate.blocks_,buffer,deb);
//     FILE* dout=fopen("kk.xml","wb");
//     fprintf(dout,"<?xml version='1.0' encoding='UTF-8'?>\n");
//     fprintf(dout,"%s",deb.v());
//     fclose(dout);
  }
#endif
}
static void markdown_evaluate(const char* fileIn,const char* dataIn,MyTSchar& fileOut,
  int is_auto,MyTScharList* extensions=NULL)
{
  MyTSchar buffer,out;
  FILE* fin=stdin,*fout=stdout;
  
  MarkdownOutputType otype=OT::html;
  SvgmlOutputType sotype=OTS::svg;
  
  if(fileIn){
    fin=fopen(fileIn,"rb");
    if(!fin){
      fprintf(stderr,"infile not found\n");
      exit(2);
    }
  }
  
  if(dataIn){
    buffer.appendV(dataIn);
  } else {
    if(fin==stdin){
      fprintf(stderr,"not implemented data from stdin\n");
      exit(2);
    }
    buffer.set_num(100);
    fread(buffer.v(),1,99,fin);
    buffer.printE("");
    if(buffer.regexp(0,"output:\\s*gid")){
      sotype=OTS::gid;
      if(is_auto){
        if(!MKstate::ip_){
          MKstate::check_init_ip();
          Tcl_Obj *ret=Tcl_SubstObj(MKstate::ip_,Tcl_NewStringObj("$::env(APPDATA)/gid_post/batch-1.bch",-1),
            TCL_SUBST_VARIABLES);
          fileOut.print0("%s",Tcl_GetString(ret));
        }
      }
    }
    fseek(fin,0,SEEK_END);
    size_t lSize=ftell(fin);
    rewind(fin);
    
    buffer.set_num(lSize);
    size_t result=fread(buffer.v(),1,lSize,fin);
    fclose(fin);
    if(result!=lSize){
      fprintf(stderr,"file read incorrectly\n");
      exit(2);
    }
    buffer.printE("");
  }
  
  if(fileIn && strlen(fileIn)>6 && strcmp(fileIn+strlen(fileIn)-6,".svgml")==0){
    if(is_auto && sotype!=OTS::gid){
      file_root(fileOut);
      fileOut.printE(".svg");
    }
    int lineNum=1,lineNum_pos=-1;
    svgml_process(sotype,buffer,out,0,buffer.num()-1,lineNum,lineNum_pos);
  } else {
    markdown_evaluate(otype,buffer,out,extensions);
  }
  
  if(fileOut.num()){
    fout=fopen(fileOut.v(),"wb");
    if(!fout){
      fprintf(stderr,"outfile not found\n");
      exit(2);
    }
  }
  fprintf(fout,"%s",out.v());
  if(fout!=stdout) fclose(fout);
}

//################################################################################
//    sync todo.txt and fossil tickets
//################################################################################

static void copy_unquote_fossil(MyTSchar& from,MyTSchar& to)
{
  to.clear();
  for(int i=0;i<from.num();i++){
    if(i<from.num()-1 && from[i]=='\\'){
      switch(from[i+1]){
        case 's': to.append(' '); break;
        case 't': to.append('\t'); break;
        case 'n': to.append('\n'); break;
        case 'r': to.append('\r'); break;
        case 'f': to.append('\f'); break;
        case 'v': to.append('\v'); break;
        case '\\': to.append('\\'); break;
        default: to.append('\\'); break;
      }
      i++;
    } else {
      to.append(from[i]);
    }
  }
}

static void copy_quote_fossil(MyTSchar& from,MyTSchar& to)
{
  to.clear();
  for(int i=0;i<from.num();i++){
    switch(from[i]){
      case ' ': to.printE("\\s"); break;
      case '\t': to.printE("\\t"); break;
      case '\n': to.printE("\\n"); break;
      case '\r': to.printE("\\r"); break;
      case '\f': to.printE("\\f"); break;
      case '\v': to.printE("\\v"); break;
      case '\\': to.printE("\\\\"); break;
      default: to.append(from[i]); break;
    }
  }
}

static const char* eval_tcl(Tcl_Interp* interp,const char* script)
{
  int result=Tcl_EvalEx(interp,script,-1,0);
  const char* ret=Tcl_GetString(Tcl_GetObjResult(interp));
  if(result!=TCL_OK){
    throw MyTSchar("error: %s",ret);
  }
  return ret;
}

static const char* eval_tcl(Tcl_Interp* interp,MyTScharList& cmdList)
{
  MyTSchar cmdline;
  string_create_tcl_list(cmdList,cmdline);
  int result=Tcl_EvalEx(interp,cmdline.v(),cmdline.num(),0);
  const char* ret=Tcl_GetString(Tcl_GetObjResult(interp));
  if(result!=TCL_OK){
    throw MyTSchar("error: %s",ret);
  }
  return ret;
}

// static const char* eval_tcl(MyTScharList& cmdList)
// {
//   Tcl_Interp* interp=Tcl_CreateInterp();
//   const char* ret=eval_tcl(interp,cmdList);
//   Tcl_DeleteInterp(interp);
//   return ret;
// }

void sync_todotxt_fossil(const char* todotxtFile,const char* fossilFile,SyncPref prefer)
{
  int completed,iFossil,isNew,isModInv,haschangesFossil,haschangesTodoTXT;
  MyTScharList cmdList;
  MyTSchar username,data,uuid,completed_date,priority,date,hour,sha1,desc,projects;
  MyTScharListH keyvalues;
  Mytextlongtable uuid_to_fossil,uuid_to_TodoTXT;
  
  try { read_fileG(todotxtFile,data,0); }
  catch(MyTSchar& c){
    UNUSED(c);
    throw MyTSchar("could not read file '%s'",todotxtFile);
  }
  data.regsub(0,"^\\s+|\\s$","");
  
  int numChangesTodoTXT=0,numUpdatesTodoTXT=0,numchangesFossil=0;
  
  Tcl_Interp* interp=Tcl_CreateInterp();
  
  cmdList.setList("set","tcl_platform(user)",NULL);
  username=eval_tcl(interp,cmdList);
  
  cmdList.setList("encoding","system","utf-8",NULL);
  eval_tcl(interp,cmdList);
  
  cmdList.setList("exec","fossil","ticket","--quote","-R",fossilFile,"show","1",NULL);
  const char* ret=eval_tcl(interp,cmdList);
  printf_debug_OFF("A---------------\n%s\n------------",ret);
  
  MyTScharList linesFossil,fieldsFossil;
  MyTSchar uuidF,dateF,hourF,statusF,priorityF,titleF,projectF,creatorF,maTS[3],tmp;
  string_split(ret,"\n",linesFossil);
  for(int i=0;i<linesFossil.num();i++){
    if(i==0) continue;
    string_split(linesFossil[i].v(),"\t",fieldsFossil);
    copy_unquote_fossil(fieldsFossil[1],uuidF);
    uuid_to_fossil.set(uuidF.v(),i);
  }
  int newFossilLine=linesFossil.num();
  if(newFossilLine==0) newFossilLine=1;
  
  MyTScharList linesTodo,errorMessages;
  MyhashvecL new_todo_to_fossil,mod_todo_to_fossil,modinv_todo_to_fossil;
  string_split(data.v(),"\n",linesTodo);
  for(int i=0;i<linesTodo.num();i++){
    parse_todo_txt(linesTodo[i].v(),completed,completed_date,priority,
      date,desc,projects,keyvalues);
    if(desc.num()==0) continue;
    uuid.clear(); hour.clear(); sha1.clear();
    int search_id=-1; const char* name; ggclong pos;
    while((pos=keyvalues.Mytextlongtable::nextv(search_id,name))!=-1){
      if(strcmp(name,"uuid")==0){
        uuid.setV(keyvalues[pos].v(),keyvalues[pos].num());
      } else if(strcmp(name,"time")==0){
        hour.setV(keyvalues[pos].v(),keyvalues[pos].num());
      } else if(strcmp(name,"sha1")==0){
        sha1.setV(keyvalues[pos].v(),keyvalues[pos].num());
      }
    }
    if(uuid.num()){
      iFossil=uuid_to_fossil.get(uuid.v());
      if(iFossil==-1){
        keyvalues.Mytextlongtable::remove("uuid");
        uuid.clear();
      }
    }
    if(uuid.num()){
      uuid_to_TodoTXT.set(uuid.v(),i);
      string_split(linesFossil[iFossil].v(),"\t",fieldsFossil);
      fieldsFossil[6].regexp(0,"(.*)\\\\s(.*)",maTS,3);
      dateF=maTS[1];
      hourF=maTS[2];
      if(strcmp(date.v(),dateF.v())!=0 || strcmp(hour.v(),hourF.v())!=0){
        haschangesFossil=1;
      } else {
        haschangesFossil=0;
      }
      MyTSchar sha1N;
      sha1_todo_txt(completed,completed_date,priority,date,desc,projects,
        keyvalues,sha1N);
      if(strcmp(sha1.v(),sha1N.v())!=0){
        haschangesTodoTXT=1;
      } else {
        haschangesTodoTXT=0;
      }
      
      if(haschangesFossil && haschangesTodoTXT && prefer!=SP::none){
        printf_debug("prefer=%s",SyncPref_g_[int(prefer)]);
        switch(prefer){
          case SP::todotxt: haschangesFossil=0; break;
          case SP::fossil: haschangesTodoTXT=0; break;
        }
      }
      if(haschangesFossil && haschangesTodoTXT){
        errorMessages.incr_num().print0("%d --- %s\n     --- %s",i+1,linesTodo[i].v(),
          linesFossil[iFossil].v());
        errorMessages[end_MTS].regsub(0,"\\\\s"," ");
      } else if(haschangesFossil){
        mod_todo_to_fossil.set(i,iFossil);
      } else if(haschangesTodoTXT){
        cmdList.setList("exec","fossil","ticket","--quote","-R",fossilFile,"set",uuid.v(),NULL);
        cmdList.appendList("priority",priority.v(),NULL);
        copy_quote_fossil(projects,tmp);
        cmdList.appendList("project",tmp.v(),NULL);
        if(completed) cmdList.appendList("status","Closed",NULL);
        else cmdList.appendList("status","Open",NULL);
        copy_quote_fossil(desc,tmp);
        cmdList.appendList("title",tmp.v(),NULL);
        copy_quote_fossil(username,tmp);
        cmdList.appendList("username",tmp.v(),NULL);
        eval_tcl(interp,cmdList);
        modinv_todo_to_fossil.set(i,iFossil);
        numchangesFossil++;
        printf_debug("    FOSSIL %d: %s",iFossil,linesFossil[iFossil].v());
        printf_debug("changed fossil. %s",linesTodo[i].v());
      }
    } else {
      cmdList.setList("exec","fossil","ticket","--quote","-R",fossilFile,"add",NULL);
      cmdList.appendList("priority",priority.v(),NULL);
      copy_quote_fossil(projects,tmp);
      cmdList.appendList("project",tmp.v(),NULL);
      if(completed) cmdList.appendList("status","Closed",NULL);
      else cmdList.appendList("status","Open",NULL);
      copy_quote_fossil(desc,tmp);
      cmdList.appendList("title",tmp.v(),NULL);
      copy_quote_fossil(username,tmp);
      cmdList.appendList("creator",tmp.v(),NULL);
      eval_tcl(interp,cmdList);
      new_todo_to_fossil.set(i,newFossilLine++);
      numchangesFossil++;
      printf_debug("added to fossil. %s",linesTodo[i].v());
    }
  }
  
  cmdList.setList("exec","fossil","ticket","--quote","-R",fossilFile,"show","1",NULL);
  ret=eval_tcl(interp,cmdList);
  printf_debug_OFF("B---------------\n%s\n------------",ret);
  string_split(ret,"\n",linesFossil);
  
  for(int i=0;i<linesTodo.num();i++){
    isModInv=0;
    if(new_todo_to_fossil.exists(i)){
      iFossil=new_todo_to_fossil.get(i);
      isNew=1;
    } else if(mod_todo_to_fossil.exists(i)){
      iFossil=mod_todo_to_fossil.get(i);
      isNew=0;
    } else if(modinv_todo_to_fossil.exists(i)){
      iFossil=modinv_todo_to_fossil.get(i);
      isModInv=1;
      isNew=0;
    } else {
      continue;
    }
    parse_todo_txt(linesTodo[i].v(),completed,completed_date,priority,
      date,desc,projects,keyvalues);
    
    string_split(linesFossil[iFossil].v(),"\t",fieldsFossil);
    printf_debug("  FOSSIL %d: %s",iFossil,linesFossil[iFossil].v());
    copy_unquote_fossil(fieldsFossil[1],uuid);
    fieldsFossil[6].regexp(0,"(.*)\\\\s(.*)",maTS,3);
    date=maTS[1];
    hourF=maTS[2];
    keyvalues.getF_H("uuid")=uuid;
    keyvalues.getF_H("time")=hourF;
    
    if(isModInv){
      numUpdatesTodoTXT++;
      printf_debug("updated todo -A-. %s",linesTodo[i].v());
    } else if(!isNew){
      copy_unquote_fossil(fieldsFossil[2],statusF);
      if(strcmp(statusF.v(),"Open")==0) completed=0;
      else completed=1;
      
      if(completed && completed_date.num()==0){
        completed_date=date;
      }
      copy_unquote_fossil(fieldsFossil[3],priority);
      copy_unquote_fossil(fieldsFossil[4],desc);
      copy_unquote_fossil(fieldsFossil[5],projects);
      copy_unquote_fossil(fieldsFossil[7],creatorF);
      if(creatorF.num()){
        keyvalues.getF_H("creator")=creatorF;
      }
      numChangesTodoTXT++;
      printf_debug("changed TODO. %s",linesTodo[i].v());
    } else {
      uuid_to_TodoTXT.set(uuid.v(),i); 
      numUpdatesTodoTXT++;
      printf_debug("updated todo -B-. %s",linesTodo[i].v());
    }
    create_todo_txt(completed,completed_date,priority,date,desc,
      projects,keyvalues,linesTodo[i]);
    printf_debug("    AFTER. %s",linesTodo[i].v());
  }
  
  for(int i=0;i<linesFossil.num();i++){
    if(i==0) continue;
    string_split(linesFossil[i].v(),"\t",fieldsFossil);
    copy_unquote_fossil(fieldsFossil[1],uuidF);
    if(uuid_to_TodoTXT.exists(uuidF.v())) continue;
    copy_unquote_fossil(fieldsFossil[2],statusF);
    if(strcmp(statusF.v(),"Open")==0) completed=0;
    else completed=1;
    
    if(completed){
      completed_date=date;
    } else {
      completed_date.clear(); 
    }
    copy_unquote_fossil(fieldsFossil[3],priority);
    copy_unquote_fossil(fieldsFossil[4],desc);
    copy_unquote_fossil(fieldsFossil[5],projects);
    fieldsFossil[6].regexp(0,"(.*)\\\\s(.*)",maTS,3);
    date=maTS[1];
    hourF=maTS[2];
    copy_unquote_fossil(fieldsFossil[7],creatorF);
    
    keyvalues.remove();
    keyvalues.getF_H("uuid")=uuidF;
    keyvalues.getF_H("time")=hourF;
    if(creatorF.num()){
      keyvalues.getF_H("creator")=creatorF;
    }
    linesTodo.incr_num();
    create_todo_txt(completed,completed_date,priority,date,desc,
      projects,keyvalues,linesTodo[end_MTS]);
    numChangesTodoTXT++;
    printf_debug("add to TODO. %s",linesTodo[end_MTS].v());
  }
  
  if(numChangesTodoTXT || numUpdatesTodoTXT){
    data=string_join(linesTodo,"\n");
    write_fileG_if_different(todotxtFile,data.v(),0);
  }
  Tcl_DeleteInterp(interp);
  
  printf("Syncronized #changes TODO=%d #changes FOSSIL=%d '%s' and '%s'\n",
    numChangesTodoTXT,numchangesFossil,todotxtFile,fossilFile);
    
  if(errorMessages.num()){
    MyTSchar errmessage;
    string_join(errorMessages,"\n- ",errmessage);
    throw MyTSchar("there are %d conflicts:\n- %s",errorMessages.num(),errmessage.v());
  }
}
  
#ifdef MARKDOWN_AS_EXE
int main(int argc,const char* argv[])
{
  int is_auto=0;
  MyTScharList files;
  MyTSchar fileOut;
  const char* fileIn=NULL,*dataIn=NULL;
  MyTScharList extensions;
    
  // only command necessary to initialize tcl
  Tcl_FindExecutable(argv[0]);
  
  font_measure_g_=new FT_FontMeasure;
  
  OptionalArgsDesc desc[]={
    {"-data",Value_OAT},
    {"-extensions",Value_OAT},
    {"-auto",NoValue_OAT},
    {"-open",NoValue_OAT},
    {"-cmdfile",Value_OAT},
    {"-directory",Value_OAT},
    {"-prefer","none|todotxt|fossil",ValueCheck_OAT},
    {"files","2",FinalValueList_OAT},
    {NULL,Unknown_OAT}
  };
  OptionalArgs opt(desc);
  try { opt.process(argc,argv,1); }
  catch(MyTSchar& c){
    fprintf(stderr,"%s\n",c.v());
    exit(2);
  }
  if(opt.exists_value("-cmdfile")){
    const char* cmdfile=opt.give_value("-cmdfile");
    MyTSchar data;
    try { read_fileG(cmdfile,data); }
    catch(MyTSchar& c){
      fprintf(stderr,"%s\n",c.v());
      exit(2);
    }
    MyTScharList lines;
    string_split(data.v(),"\n",lines);
    int i_ok=-1;
    for(int i=0;i<lines.num();i++){
      if(lines[i].regexp(0,"^\\s*(#|<!--|$)")==0){
        i_ok=i;
        break;
      }
    }
    if(i_ok==-1){
      fprintf(stderr,"cmdfile '%s' has no valid arguments\n",cmdfile);
      exit(2);
    }
    MyTScharList args;
    string_split_tcl_list(lines[i_ok].v(),args);
    try { opt.process(args,0); }
    catch(MyTSchar& c){
      fprintf(stderr,"%s\n",c.v());
      exit(2);
    }
  }
  if(opt.exists_value("-directory")){
    const char* directory=opt.give_value("-directory");
    int ret=chdir(directory);
    if(ret==-1){
      fprintf(stderr,"could not change to directory '%s'\n",directory);
      perror("error");
      exit(2);
    }
  }
  
  MyTSchar* data=opt.give_valueTS("-data");
  if(data){
    dataIn=data->v();
  }
  MyTSchar* extensionsTS=opt.give_valueTS("-extensions");
  if(extensionsTS){
    string_split_tcl_list(extensionsTS->v(),extensions);
  }
  
  opt.give_valueList("files",files);
  if(files.num()>=1){
    if(!data){
      fileIn=files[0].v();
    } else {
      fileOut=files[0];
    }
  }
  if(files.num()>=2){
    if(!data){
      fileOut=files[1];
    } else {
      fprintf(stderr,"not valid -data and two files\n");
      exit(2);
    }
  }
  if(opt.exists_value("-auto") && fileIn && fileOut.num()==0){
    fileOut.print0("%s",fileIn);
    file_root(fileOut);
    fileOut.printE(".html");
    is_auto=1;
  }
  
  if(files.num()==2 && file_is_extension(files[0].v(),files[0].num(),".txt") &&
    file_is_extension(files[1].v(),files[1].num(),".fsl")){
    SyncPref prefer=SyncPref(opt.give_valueOPT("-prefer",0));
    try { sync_todotxt_fossil(files[0].v(),files[1].v(),prefer); }
    catch(MyTSchar& message){
      fprintf(stderr,"%s\n",message.v());
      exit(2);
    }
    return 0;
  }
  try { markdown_evaluate(fileIn,dataIn,fileOut,is_auto,&extensions); }
  catch(MyTSchar& message){
    fprintf(stderr,"%s\n",message.v());
    exit(2);
  }
  if(opt.exists_value("-open") && fileOut.num()){
    MyTSchar cmdline;
    if(file_is_extension(fileOut.v(),fileOut.num(),".html")){
#ifdef _WIN32
      cmdline.print(0,"exec cmd /c start \"\" {%s}",fileOut.v());
#else
      cmdline.print(0,"exec xdg-open {%s} &",fileOut.v());
#endif
    } else if(file_is_extension(fileOut.v(),fileOut.num(),".svg")){
#ifdef _WIN32
      cmdline.print(0,"exec cmd /c start \"\" {%s}",fileOut.v());
#else
      cmdline.print(0,"exec xdg-open {%s} &",fileOut.v());
#endif
    } else if(file_is_extension(fileOut.v(),fileOut.num(),".bch")){
      cmdline.print(0,"exec tclsh $::env(HOME)/%s -pre -p compassfem -b {%s}",
        "mytcltk/gid_groups_conds_dir/src/full/full.tcl",fileOut.v());
    }
    Tcl_Interp* interp=Tcl_CreateInterp();
    int result=Tcl_EvalEx(interp,cmdline.v(),cmdline.num(),0);
    if(result!=TCL_OK){
      fprintf(stderr,"error: %s\n",Tcl_GetString(Tcl_GetObjResult(interp)));
      exit(2);
    }
  }
  return 0;
}
#else

static int Markdown_evaluate(ClientData clientData, Tcl_Interp *ip, int objc,Tcl_Obj *CONST objv[])
{
  int result,iMatch;
  MyTSchar buffer,out;
  const char* varname=NULL;
  MyTScharList extensions;
  
  char err_args[]= "?-variable varname? ?-svgml? -extensions \"ext1 0|1 ext2 0|1\" "
    "html|rdinfo content";
  const char *markdown_options[] = { "-variable","-svgml","-extensions",NULL };
  const char *markdown_cmds[] = { "html","rdinfo",NULL };
  
  int svgml=0;
  
  while(objc>3 && Tcl_GetString(objv[1])[0]=='-'){
    result=Tcl_GetIndexFromObj(ip,objv[1],markdown_options,"option", 0,&iMatch);
    if(result!=TCL_OK) return result;
    switch(iMatch){
      case 0:
      {
        if(objc<4){
          Tcl_WrongNumArgs(ip,1,objv, err_args);
          return TCL_ERROR;
        }
        objc--;
        objv++;
        varname=Tcl_GetString(objv[1]);
      }
      break;
      case 1:
      {
        svgml=1;
      }
      break;
      case 2:
      {
        if(objc<4){
          Tcl_WrongNumArgs(ip,1,objv, err_args);
          return TCL_ERROR;
        }
        objc--;
        objv++;
        string_split_tcl_list(Tcl_GetString(objv[1]),extensions);
      }
      break;
    }
    objc--;
    objv++;  
  }
  if (objc != 3) {
    Tcl_WrongNumArgs(ip,1,objv,err_args);
    return TCL_ERROR;
  }
  result=Tcl_GetIndexFromObj(ip,objv[1],markdown_cmds,"option", 0,&iMatch);
  if(result!=TCL_OK) return result;
  MarkdownOutputType otype=(MarkdownOutputType) (iMatch+1);
  objc--;
  objv++;
  
  buffer.setV(Tcl_GetString(objv[1]),-1);
  
  try {
    if(svgml){
      int lineNum=1,lineNum_pos=-1;
      out.printE("0 n");
      svgml_process(OTS::rdinfo,buffer,out,0,buffer.num()-1,lineNum,lineNum_pos);
    } else {
      markdown_evaluate(otype,buffer,out,&extensions);
    }
  }
  catch(MyTSchar& message){
    Tcl_SetObjResult(ip,Tcl_NewStringObj(message.v(),message.num()));
    return TCL_ERROR;
  }
  Tcl_Obj *blockinfo=Tcl_NewStringObj(out.v(),out.num());
  
  if(varname){
    Tcl_UpVar(ip,"1",varname,"blockinfo",0);
    Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);
    //Tcl_DecrRefCount(blockinfo);
  } else {
    Tcl_SetObjResult(ip,blockinfo);
  }
  return TCL_OK;
}

static int svgml_evaluate(ClientData clientData, Tcl_Interp *ip, int objc,Tcl_Obj *CONST objv[])
{
  int result,iMatch;
  MyTSchar buffer,out;
  const char* varname=NULL;
  
  char err_args[]= "?-variable varname? svg|rdinfo content";
  const char *svgml_options[] = { "-variable",NULL };
  const char *svgml_cmds[] = { "svg","rdinfo","tabinfo","gid",NULL };
  
  while(objc>3 && Tcl_GetString(objv[1])[0]=='-'){
    result=Tcl_GetIndexFromObj(ip,objv[1],svgml_options,"option", 0,&iMatch);
    if(result!=TCL_OK) return result;
    switch(iMatch){
      case 0:
      {
        if(objc<4){
          Tcl_WrongNumArgs(ip,1,objv, err_args);
          return TCL_ERROR;
        }
        objc--;
        objv++;
        varname=Tcl_GetString(objv[1]);
      }
      break;
    }
    objc--;
    objv++;  
  }
  if (objc != 3) {
    Tcl_WrongNumArgs(ip,1,objv,err_args);
    return TCL_ERROR;
  }
  result=Tcl_GetIndexFromObj(ip,objv[1],svgml_cmds,"option", 0,&iMatch);
  if(result!=TCL_OK) return result;
  SvgmlOutputType otype=(SvgmlOutputType) (iMatch+1);
  objc--;
  objv++;
  
  buffer.setV(Tcl_GetString(objv[1]),-1);

  int lineNum=1,lineNum_pos=-1;
  if(otype==OTS::rdinfo){
    out.printE("0 n");
  }

  try {
    svgml_process(otype,buffer,out,0,buffer.num()-1,lineNum,lineNum_pos);
  }
  catch(MyTSchar& message){
    Tcl_SetObjResult(ip,Tcl_NewStringObj(message.v(),message.num()));
    return TCL_ERROR;
  }
  Tcl_Obj *blockinfo=Tcl_NewStringObj(out.v(),out.num());
  
  if(varname){
    Tcl_UpVar(ip,"1",varname,"blockinfo",0);
    Tcl_SetVar2Ex(ip,"blockinfo",NULL,blockinfo,0);
    //Tcl_DecrRefCount(blockinfo);
  } else {
    Tcl_SetObjResult(ip,blockinfo);
  }
  return TCL_OK;
}

static int sync_todotxt_fossilCB(ClientData clientData, Tcl_Interp *ip, int objc,Tcl_Obj *CONST objv[])
{
  MyTSchar buffer,out;
  const char* varname=NULL;
  
  char err_args[]= "todotxtFile fossilFile";

  if (objc != 3) {
    Tcl_WrongNumArgs(ip,1,objv,err_args);
    return TCL_ERROR;
  }
  try { sync_todotxt_fossil(Tcl_GetString(objv[1]),Tcl_GetString(objv[2])); }
  catch(MyTSchar& message){
    Tcl_SetObjResult(ip,Tcl_NewStringObj(message.v(),message.num()));
    return TCL_ERROR;
  }
  return TCL_OK;
}

extern "C" DLLEXPORT int Markdown_Init(Tcl_Interp *interp)
{
#ifdef USE_TCL_STUBS
  Tcl_InitStubs(interp,"8.6",0);
#endif
  
  font_measure_g_=new FT_FontMeasure;
  
  Tcl_CreateObjCommand( interp, "markdown_evaluate",Markdown_evaluate,NULL,NULL);
  Tcl_CreateObjCommand( interp, "svgml_evaluate",svgml_evaluate,NULL,NULL);
  Tcl_CreateObjCommand( interp, "measure_text",measure_text,NULL,NULL);
  Tcl_CreateObjCommand( interp, "sync_todotxt_fossil",sync_todotxt_fossilCB,NULL,NULL);
  return TCL_OK;
}

extern "C" DLLEXPORT int Markdown_SafeInit(Tcl_Interp *interp)
{
  return Markdown_Init(interp);
}

extern "C" DLLEXPORT int Markdown_Unload(Tcl_Interp *interp,int flags)
{
  return TCL_ERROR;
}

extern "C" DLLEXPORT int Markdown_SafeUnload(Tcl_Interp *interp,int flags)
{
  return TCL_ERROR;
}
#endif // MARKDOWN_AS_EXE

const char* entities_json_to_c_g_[]={
  "&AElig","\\u00C6",
  "&AElig;","\\u00C6",
  "&AMP","\\u0026",
  "&AMP;","\\u0026",
  "&Aacute","\\u00C1",
  "&Aacute;","\\u00C1",
  "&Abreve;","\\u0102",
  "&Acirc","\\u00C2",
  "&Acirc;","\\u00C2",
  "&Acy;","\\u0410",
  "&Afr;","\\uD835\\uDD04",
  "&Agrave","\\u00C0",
  "&Agrave;","\\u00C0",
  "&Alpha;","\\u0391",
  "&Amacr;","\\u0100",
  "&And;","\\u2A53",
  "&Aogon;","\\u0104",
  "&Aopf;","\\uD835\\uDD38",
  "&ApplyFunction;","\\u2061",
  "&Aring","\\u00C5",
  "&Aring;","\\u00C5",
  "&Ascr;","\\uD835\\uDC9C",
  "&Assign;","\\u2254",
  "&Atilde","\\u00C3",
  "&Atilde;","\\u00C3",
  "&Auml","\\u00C4",
  "&Auml;","\\u00C4",
  "&Backslash;","\\u2216",
  "&Barv;","\\u2AE7",
  "&Barwed;","\\u2306",
  "&Bcy;","\\u0411",
  "&Because;","\\u2235",
  "&Bernoullis;","\\u212C",
  "&Beta;","\\u0392",
  "&Bfr;","\\uD835\\uDD05",
  "&Bopf;","\\uD835\\uDD39",
  "&Breve;","\\u02D8",
  "&Bscr;","\\u212C",
  "&Bumpeq;","\\u224E",
  "&CHcy;","\\u0427",
  "&COPY","\\u00A9",
  "&COPY;","\\u00A9",
  "&Cacute;","\\u0106",
  "&Cap;","\\u22D2",
  "&CapitalDifferentialD;","\\u2145",
  "&Cayleys;","\\u212D",
  "&Ccaron;","\\u010C",
  "&Ccedil","\\u00C7",
  "&Ccedil;","\\u00C7",
  "&Ccirc;","\\u0108",
  "&Cconint;","\\u2230",
  "&Cdot;","\\u010A",
  "&Cedilla;","\\u00B8",
  "&CenterDot;","\\u00B7",
  "&Cfr;","\\u212D",
  "&Chi;","\\u03A7",
  "&CircleDot;","\\u2299",
  "&CircleMinus;","\\u2296",
  "&CirclePlus;","\\u2295",
  "&CircleTimes;","\\u2297",
  "&ClockwiseContourIntegral;","\\u2232",
  "&CloseCurlyDoubleQuote;","\\u201D",
  "&CloseCurlyQuote;","\\u2019",
  "&Colon;","\\u2237",
  "&Colone;","\\u2A74",
  "&Congruent;","\\u2261",
  "&Conint;","\\u222F",
  "&ContourIntegral;","\\u222E",
  "&Copf;","\\u2102",
  "&Coproduct;","\\u2210",
  "&CounterClockwiseContourIntegral;","\\u2233",
  "&Cross;","\\u2A2F",
  "&Cscr;","\\uD835\\uDC9E",
  "&Cup;","\\u22D3",
  "&CupCap;","\\u224D",
  "&DD;","\\u2145",
  "&DDotrahd;","\\u2911",
  "&DJcy;","\\u0402",
  "&DScy;","\\u0405",
  "&DZcy;","\\u040F",
  "&Dagger;","\\u2021",
  "&Darr;","\\u21A1",
  "&Dashv;","\\u2AE4",
  "&Dcaron;","\\u010E",
  "&Dcy;","\\u0414",
  "&Del;","\\u2207",
  "&Delta;","\\u0394",
  "&Dfr;","\\uD835\\uDD07",
  "&DiacriticalAcute;","\\u00B4",
  "&DiacriticalDot;","\\u02D9",
  "&DiacriticalDoubleAcute;","\\u02DD",
  "&DiacriticalGrave;","\\u0060",
  "&DiacriticalTilde;","\\u02DC",
  "&Diamond;","\\u22C4",
  "&DifferentialD;","\\u2146",
  "&Dopf;","\\uD835\\uDD3B",
  "&Dot;","\\u00A8",
  "&DotDot;","\\u20DC",
  "&DotEqual;","\\u2250",
  "&DoubleContourIntegral;","\\u222F",
  "&DoubleDot;","\\u00A8",
  "&DoubleDownArrow;","\\u21D3",
  "&DoubleLeftArrow;","\\u21D0",
  "&DoubleLeftRightArrow;","\\u21D4",
  "&DoubleLeftTee;","\\u2AE4",
  "&DoubleLongLeftArrow;","\\u27F8",
  "&DoubleLongLeftRightArrow;","\\u27FA",
  "&DoubleLongRightArrow;","\\u27F9",
  "&DoubleRightArrow;","\\u21D2",
  "&DoubleRightTee;","\\u22A8",
  "&DoubleUpArrow;","\\u21D1",
  "&DoubleUpDownArrow;","\\u21D5",
  "&DoubleVerticalBar;","\\u2225",
  "&DownArrow;","\\u2193",
  "&DownArrowBar;","\\u2913",
  "&DownArrowUpArrow;","\\u21F5",
  "&DownBreve;","\\u0311",
  "&DownLeftRightVector;","\\u2950",
  "&DownLeftTeeVector;","\\u295E",
  "&DownLeftVector;","\\u21BD",
  "&DownLeftVectorBar;","\\u2956",
  "&DownRightTeeVector;","\\u295F",
  "&DownRightVector;","\\u21C1",
  "&DownRightVectorBar;","\\u2957",
  "&DownTee;","\\u22A4",
  "&DownTeeArrow;","\\u21A7",
  "&Downarrow;","\\u21D3",
  "&Dscr;","\\uD835\\uDC9F",
  "&Dstrok;","\\u0110",
  "&ENG;","\\u014A",
  "&ETH","\\u00D0",
  "&ETH;","\\u00D0",
  "&Eacute","\\u00C9",
  "&Eacute;","\\u00C9",
  "&Ecaron;","\\u011A",
  "&Ecirc","\\u00CA",
  "&Ecirc;","\\u00CA",
  "&Ecy;","\\u042D",
  "&Edot;","\\u0116",
  "&Efr;","\\uD835\\uDD08",
  "&Egrave","\\u00C8",
  "&Egrave;","\\u00C8",
  "&Element;","\\u2208",
  "&Emacr;","\\u0112",
  "&EmptySmallSquare;","\\u25FB",
  "&EmptyVerySmallSquare;","\\u25AB",
  "&Eogon;","\\u0118",
  "&Eopf;","\\uD835\\uDD3C",
  "&Epsilon;","\\u0395",
  "&Equal;","\\u2A75",
  "&EqualTilde;","\\u2242",
  "&Equilibrium;","\\u21CC",
  "&Escr;","\\u2130",
  "&Esim;","\\u2A73",
  "&Eta;","\\u0397",
  "&Euml","\\u00CB",
  "&Euml;","\\u00CB",
  "&Exists;","\\u2203",
  "&ExponentialE;","\\u2147",
  "&Fcy;","\\u0424",
  "&Ffr;","\\uD835\\uDD09",
  "&FilledSmallSquare;","\\u25FC",
  "&FilledVerySmallSquare;","\\u25AA",
  "&Fopf;","\\uD835\\uDD3D",
  "&ForAll;","\\u2200",
  "&Fouriertrf;","\\u2131",
  "&Fscr;","\\u2131",
  "&GJcy;","\\u0403",
  "&GT","\\u003E",
  "&GT;","\\u003E",
  "&Gamma;","\\u0393",
  "&Gammad;","\\u03DC",
  "&Gbreve;","\\u011E",
  "&Gcedil;","\\u0122",
  "&Gcirc;","\\u011C",
  "&Gcy;","\\u0413",
  "&Gdot;","\\u0120",
  "&Gfr;","\\uD835\\uDD0A",
  "&Gg;","\\u22D9",
  "&Gopf;","\\uD835\\uDD3E",
  "&GreaterEqual;","\\u2265",
  "&GreaterEqualLess;","\\u22DB",
  "&GreaterFullEqual;","\\u2267",
  "&GreaterGreater;","\\u2AA2",
  "&GreaterLess;","\\u2277",
  "&GreaterSlantEqual;","\\u2A7E",
  "&GreaterTilde;","\\u2273",
  "&Gscr;","\\uD835\\uDCA2",
  "&Gt;","\\u226B",
  "&HARDcy;","\\u042A",
  "&Hacek;","\\u02C7",
  "&Hat;","\\u005E",
  "&Hcirc;","\\u0124",
  "&Hfr;","\\u210C",
  "&HilbertSpace;","\\u210B",
  "&Hopf;","\\u210D",
  "&HorizontalLine;","\\u2500",
  "&Hscr;","\\u210B",
  "&Hstrok;","\\u0126",
  "&HumpDownHump;","\\u224E",
  "&HumpEqual;","\\u224F",
  "&IEcy;","\\u0415",
  "&IJlig;","\\u0132",
  "&IOcy;","\\u0401",
  "&Iacute","\\u00CD",
  "&Iacute;","\\u00CD",
  "&Icirc","\\u00CE",
  "&Icirc;","\\u00CE",
  "&Icy;","\\u0418",
  "&Idot;","\\u0130",
  "&Ifr;","\\u2111",
  "&Igrave","\\u00CC",
  "&Igrave;","\\u00CC",
  "&Im;","\\u2111",
  "&Imacr;","\\u012A",
  "&ImaginaryI;","\\u2148",
  "&Implies;","\\u21D2",
  "&Int;","\\u222C",
  "&Integral;","\\u222B",
  "&Intersection;","\\u22C2",
  "&InvisibleComma;","\\u2063",
  "&InvisibleTimes;","\\u2062",
  "&Iogon;","\\u012E",
  "&Iopf;","\\uD835\\uDD40",
  "&Iota;","\\u0399",
  "&Iscr;","\\u2110",
  "&Itilde;","\\u0128",
  "&Iukcy;","\\u0406",
  "&Iuml","\\u00CF",
  "&Iuml;","\\u00CF",
  "&Jcirc;","\\u0134",
  "&Jcy;","\\u0419",
  "&Jfr;","\\uD835\\uDD0D",
  "&Jopf;","\\uD835\\uDD41",
  "&Jscr;","\\uD835\\uDCA5",
  "&Jsercy;","\\u0408",
  "&Jukcy;","\\u0404",
  "&KHcy;","\\u0425",
  "&KJcy;","\\u040C",
  "&Kappa;","\\u039A",
  "&Kcedil;","\\u0136",
  "&Kcy;","\\u041A",
  "&Kfr;","\\uD835\\uDD0E",
  "&Kopf;","\\uD835\\uDD42",
  "&Kscr;","\\uD835\\uDCA6",
  "&LJcy;","\\u0409",
  "&LT","\\u003C",
  "&LT;","\\u003C",
  "&Lacute;","\\u0139",
  "&Lambda;","\\u039B",
  "&Lang;","\\u27EA",
  "&Laplacetrf;","\\u2112",
  "&Larr;","\\u219E",
  "&Lcaron;","\\u013D",
  "&Lcedil;","\\u013B",
  "&Lcy;","\\u041B",
  "&LeftAngleBracket;","\\u27E8",
  "&LeftArrow;","\\u2190",
  "&LeftArrowBar;","\\u21E4",
  "&LeftArrowRightArrow;","\\u21C6",
  "&LeftCeiling;","\\u2308",
  "&LeftDoubleBracket;","\\u27E6",
  "&LeftDownTeeVector;","\\u2961",
  "&LeftDownVector;","\\u21C3",
  "&LeftDownVectorBar;","\\u2959",
  "&LeftFloor;","\\u230A",
  "&LeftRightArrow;","\\u2194",
  "&LeftRightVector;","\\u294E",
  "&LeftTee;","\\u22A3",
  "&LeftTeeArrow;","\\u21A4",
  "&LeftTeeVector;","\\u295A",
  "&LeftTriangle;","\\u22B2",
  "&LeftTriangleBar;","\\u29CF",
  "&LeftTriangleEqual;","\\u22B4",
  "&LeftUpDownVector;","\\u2951",
  "&LeftUpTeeVector;","\\u2960",
  "&LeftUpVector;","\\u21BF",
  "&LeftUpVectorBar;","\\u2958",
  "&LeftVector;","\\u21BC",
  "&LeftVectorBar;","\\u2952",
  "&Leftarrow;","\\u21D0",
  "&Leftrightarrow;","\\u21D4",
  "&LessEqualGreater;","\\u22DA",
  "&LessFullEqual;","\\u2266",
  "&LessGreater;","\\u2276",
  "&LessLess;","\\u2AA1",
  "&LessSlantEqual;","\\u2A7D",
  "&LessTilde;","\\u2272",
  "&Lfr;","\\uD835\\uDD0F",
  "&Ll;","\\u22D8",
  "&Lleftarrow;","\\u21DA",
  "&Lmidot;","\\u013F",
  "&LongLeftArrow;","\\u27F5",
  "&LongLeftRightArrow;","\\u27F7",
  "&LongRightArrow;","\\u27F6",
  "&Longleftarrow;","\\u27F8",
  "&Longleftrightarrow;","\\u27FA",
  "&Longrightarrow;","\\u27F9",
  "&Lopf;","\\uD835\\uDD43",
  "&LowerLeftArrow;","\\u2199",
  "&LowerRightArrow;","\\u2198",
  "&Lscr;","\\u2112",
  "&Lsh;","\\u21B0",
  "&Lstrok;","\\u0141",
  "&Lt;","\\u226A",
  "&Map;","\\u2905",
  "&Mcy;","\\u041C",
  "&MediumSpace;","\\u205F",
  "&Mellintrf;","\\u2133",
  "&Mfr;","\\uD835\\uDD10",
  "&MinusPlus;","\\u2213",
  "&Mopf;","\\uD835\\uDD44",
  "&Mscr;","\\u2133",
  "&Mu;","\\u039C",
  "&NJcy;","\\u040A",
  "&Nacute;","\\u0143",
  "&Ncaron;","\\u0147",
  "&Ncedil;","\\u0145",
  "&Ncy;","\\u041D",
  "&NegativeMediumSpace;","\\u200B",
  "&NegativeThickSpace;","\\u200B",
  "&NegativeThinSpace;","\\u200B",
  "&NegativeVeryThinSpace;","\\u200B",
  "&NestedGreaterGreater;","\\u226B",
  "&NestedLessLess;","\\u226A",
  "&NewLine;","\\u000A",
  "&Nfr;","\\uD835\\uDD11",
  "&NoBreak;","\\u2060",
  "&NonBreakingSpace;","\\u00A0",
  "&Nopf;","\\u2115",
  "&Not;","\\u2AEC",
  "&NotCongruent;","\\u2262",
  "&NotCupCap;","\\u226D",
  "&NotDoubleVerticalBar;","\\u2226",
  "&NotElement;","\\u2209",
  "&NotEqual;","\\u2260",
  "&NotEqualTilde;","\\u2242\\u0338",
  "&NotExists;","\\u2204",
  "&NotGreater;","\\u226F",
  "&NotGreaterEqual;","\\u2271",
  "&NotGreaterFullEqual;","\\u2267\\u0338",
  "&NotGreaterGreater;","\\u226B\\u0338",
  "&NotGreaterLess;","\\u2279",
  "&NotGreaterSlantEqual;","\\u2A7E\\u0338",
  "&NotGreaterTilde;","\\u2275",
  "&NotHumpDownHump;","\\u224E\\u0338",
  "&NotHumpEqual;","\\u224F\\u0338",
  "&NotLeftTriangle;","\\u22EA",
  "&NotLeftTriangleBar;","\\u29CF\\u0338",
  "&NotLeftTriangleEqual;","\\u22EC",
  "&NotLess;","\\u226E",
  "&NotLessEqual;","\\u2270",
  "&NotLessGreater;","\\u2278",
  "&NotLessLess;","\\u226A\\u0338",
  "&NotLessSlantEqual;","\\u2A7D\\u0338",
  "&NotLessTilde;","\\u2274",
  "&NotNestedGreaterGreater;","\\u2AA2\\u0338",
  "&NotNestedLessLess;","\\u2AA1\\u0338",
  "&NotPrecedes;","\\u2280",
  "&NotPrecedesEqual;","\\u2AAF\\u0338",
  "&NotPrecedesSlantEqual;","\\u22E0",
  "&NotReverseElement;","\\u220C",
  "&NotRightTriangle;","\\u22EB",
  "&NotRightTriangleBar;","\\u29D0\\u0338",
  "&NotRightTriangleEqual;","\\u22ED",
  "&NotSquareSubset;","\\u228F\\u0338",
  "&NotSquareSubsetEqual;","\\u22E2",
  "&NotSquareSuperset;","\\u2290\\u0338",
  "&NotSquareSupersetEqual;","\\u22E3",
  "&NotSubset;","\\u2282\\u20D2",
  "&NotSubsetEqual;","\\u2288",
  "&NotSucceeds;","\\u2281",
  "&NotSucceedsEqual;","\\u2AB0\\u0338",
  "&NotSucceedsSlantEqual;","\\u22E1",
  "&NotSucceedsTilde;","\\u227F\\u0338",
  "&NotSuperset;","\\u2283\\u20D2",
  "&NotSupersetEqual;","\\u2289",
  "&NotTilde;","\\u2241",
  "&NotTildeEqual;","\\u2244",
  "&NotTildeFullEqual;","\\u2247",
  "&NotTildeTilde;","\\u2249",
  "&NotVerticalBar;","\\u2224",
  "&Nscr;","\\uD835\\uDCA9",
  "&Ntilde","\\u00D1",
  "&Ntilde;","\\u00D1",
  "&Nu;","\\u039D",
  "&OElig;","\\u0152",
  "&Oacute","\\u00D3",
  "&Oacute;","\\u00D3",
  "&Ocirc","\\u00D4",
  "&Ocirc;","\\u00D4",
  "&Ocy;","\\u041E",
  "&Odblac;","\\u0150",
  "&Ofr;","\\uD835\\uDD12",
  "&Ograve","\\u00D2",
  "&Ograve;","\\u00D2",
  "&Omacr;","\\u014C",
  "&Omega;","\\u03A9",
  "&Omicron;","\\u039F",
  "&Oopf;","\\uD835\\uDD46",
  "&OpenCurlyDoubleQuote;","\\u201C",
  "&OpenCurlyQuote;","\\u2018",
  "&Or;","\\u2A54",
  "&Oscr;","\\uD835\\uDCAA",
  "&Oslash","\\u00D8",
  "&Oslash;","\\u00D8",
  "&Otilde","\\u00D5",
  "&Otilde;","\\u00D5",
  "&Otimes;","\\u2A37",
  "&Ouml","\\u00D6",
  "&Ouml;","\\u00D6",
  "&OverBar;","\\u203E",
  "&OverBrace;","\\u23DE",
  "&OverBracket;","\\u23B4",
  "&OverParenthesis;","\\u23DC",
  "&PartialD;","\\u2202",
  "&Pcy;","\\u041F",
  "&Pfr;","\\uD835\\uDD13",
  "&Phi;","\\u03A6",
  "&Pi;","\\u03A0",
  "&PlusMinus;","\\u00B1",
  "&Poincareplane;","\\u210C",
  "&Popf;","\\u2119",
  "&Pr;","\\u2ABB",
  "&Precedes;","\\u227A",
  "&PrecedesEqual;","\\u2AAF",
  "&PrecedesSlantEqual;","\\u227C",
  "&PrecedesTilde;","\\u227E",
  "&Prime;","\\u2033",
  "&Product;","\\u220F",
  "&Proportion;","\\u2237",
  "&Proportional;","\\u221D",
  "&Pscr;","\\uD835\\uDCAB",
  "&Psi;","\\u03A8",
  "&QUOT","\\u0022",
  "&QUOT;","\\u0022",
  "&Qfr;","\\uD835\\uDD14",
  "&Qopf;","\\u211A",
  "&Qscr;","\\uD835\\uDCAC",
  "&RBarr;","\\u2910",
  "&REG","\\u00AE",
  "&REG;","\\u00AE",
  "&Racute;","\\u0154",
  "&Rang;","\\u27EB",
  "&Rarr;","\\u21A0",
  "&Rarrtl;","\\u2916",
  "&Rcaron;","\\u0158",
  "&Rcedil;","\\u0156",
  "&Rcy;","\\u0420",
  "&Re;","\\u211C",
  "&ReverseElement;","\\u220B",
  "&ReverseEquilibrium;","\\u21CB",
  "&ReverseUpEquilibrium;","\\u296F",
  "&Rfr;","\\u211C",
  "&Rho;","\\u03A1",
  "&RightAngleBracket;","\\u27E9",
  "&RightArrow;","\\u2192",
  "&RightArrowBar;","\\u21E5",
  "&RightArrowLeftArrow;","\\u21C4",
  "&RightCeiling;","\\u2309",
  "&RightDoubleBracket;","\\u27E7",
  "&RightDownTeeVector;","\\u295D",
  "&RightDownVector;","\\u21C2",
  "&RightDownVectorBar;","\\u2955",
  "&RightFloor;","\\u230B",
  "&RightTee;","\\u22A2",
  "&RightTeeArrow;","\\u21A6",
  "&RightTeeVector;","\\u295B",
  "&RightTriangle;","\\u22B3",
  "&RightTriangleBar;","\\u29D0",
  "&RightTriangleEqual;","\\u22B5",
  "&RightUpDownVector;","\\u294F",
  "&RightUpTeeVector;","\\u295C",
  "&RightUpVector;","\\u21BE",
  "&RightUpVectorBar;","\\u2954",
  "&RightVector;","\\u21C0",
  "&RightVectorBar;","\\u2953",
  "&Rightarrow;","\\u21D2",
  "&Ropf;","\\u211D",
  "&RoundImplies;","\\u2970",
  "&Rrightarrow;","\\u21DB",
  "&Rscr;","\\u211B",
  "&Rsh;","\\u21B1",
  "&RuleDelayed;","\\u29F4",
  "&SHCHcy;","\\u0429",
  "&SHcy;","\\u0428",
  "&SOFTcy;","\\u042C",
  "&Sacute;","\\u015A",
  "&Sc;","\\u2ABC",
  "&Scaron;","\\u0160",
  "&Scedil;","\\u015E",
  "&Scirc;","\\u015C",
  "&Scy;","\\u0421",
  "&Sfr;","\\uD835\\uDD16",
  "&ShortDownArrow;","\\u2193",
  "&ShortLeftArrow;","\\u2190",
  "&ShortRightArrow;","\\u2192",
  "&ShortUpArrow;","\\u2191",
  "&Sigma;","\\u03A3",
  "&SmallCircle;","\\u2218",
  "&Sopf;","\\uD835\\uDD4A",
  "&Sqrt;","\\u221A",
  "&Square;","\\u25A1",
  "&SquareIntersection;","\\u2293",
  "&SquareSubset;","\\u228F",
  "&SquareSubsetEqual;","\\u2291",
  "&SquareSuperset;","\\u2290",
  "&SquareSupersetEqual;","\\u2292",
  "&SquareUnion;","\\u2294",
  "&Sscr;","\\uD835\\uDCAE",
  "&Star;","\\u22C6",
  "&Sub;","\\u22D0",
  "&Subset;","\\u22D0",
  "&SubsetEqual;","\\u2286",
  "&Succeeds;","\\u227B",
  "&SucceedsEqual;","\\u2AB0",
  "&SucceedsSlantEqual;","\\u227D",
  "&SucceedsTilde;","\\u227F",
  "&SuchThat;","\\u220B",
  "&Sum;","\\u2211",
  "&Sup;","\\u22D1",
  "&Superset;","\\u2283",
  "&SupersetEqual;","\\u2287",
  "&Supset;","\\u22D1",
  "&THORN","\\u00DE",
  "&THORN;","\\u00DE",
  "&TRADE;","\\u2122",
  "&TSHcy;","\\u040B",
  "&TScy;","\\u0426",
  "&Tab;","\\u0009",
  "&Tau;","\\u03A4",
  "&Tcaron;","\\u0164",
  "&Tcedil;","\\u0162",
  "&Tcy;","\\u0422",
  "&Tfr;","\\uD835\\uDD17",
  "&Therefore;","\\u2234",
  "&Theta;","\\u0398",
  "&ThickSpace;","\\u205F\\u200A",
  "&ThinSpace;","\\u2009",
  "&Tilde;","\\u223C",
  "&TildeEqual;","\\u2243",
  "&TildeFullEqual;","\\u2245",
  "&TildeTilde;","\\u2248",
  "&Topf;","\\uD835\\uDD4B",
  "&TripleDot;","\\u20DB",
  "&Tscr;","\\uD835\\uDCAF",
  "&Tstrok;","\\u0166",
  "&Uacute","\\u00DA",
  "&Uacute;","\\u00DA",
  "&Uarr;","\\u219F",
  "&Uarrocir;","\\u2949",
  "&Ubrcy;","\\u040E",
  "&Ubreve;","\\u016C",
  "&Ucirc","\\u00DB",
  "&Ucirc;","\\u00DB",
  "&Ucy;","\\u0423",
  "&Udblac;","\\u0170",
  "&Ufr;","\\uD835\\uDD18",
  "&Ugrave","\\u00D9",
  "&Ugrave;","\\u00D9",
  "&Umacr;","\\u016A",
  "&UnderBar;","\\u005F",
  "&UnderBrace;","\\u23DF",
  "&UnderBracket;","\\u23B5",
  "&UnderParenthesis;","\\u23DD",
  "&Union;","\\u22C3",
  "&UnionPlus;","\\u228E",
  "&Uogon;","\\u0172",
  "&Uopf;","\\uD835\\uDD4C",
  "&UpArrow;","\\u2191",
  "&UpArrowBar;","\\u2912",
  "&UpArrowDownArrow;","\\u21C5",
  "&UpDownArrow;","\\u2195",
  "&UpEquilibrium;","\\u296E",
  "&UpTee;","\\u22A5",
  "&UpTeeArrow;","\\u21A5",
  "&Uparrow;","\\u21D1",
  "&Updownarrow;","\\u21D5",
  "&UpperLeftArrow;","\\u2196",
  "&UpperRightArrow;","\\u2197",
  "&Upsi;","\\u03D2",
  "&Upsilon;","\\u03A5",
  "&Uring;","\\u016E",
  "&Uscr;","\\uD835\\uDCB0",
  "&Utilde;","\\u0168",
  "&Uuml","\\u00DC",
  "&Uuml;","\\u00DC",
  "&VDash;","\\u22AB",
  "&Vbar;","\\u2AEB",
  "&Vcy;","\\u0412",
  "&Vdash;","\\u22A9",
  "&Vdashl;","\\u2AE6",
  "&Vee;","\\u22C1",
  "&Verbar;","\\u2016",
  "&Vert;","\\u2016",
  "&VerticalBar;","\\u2223",
  "&VerticalLine;","\\u007C",
  "&VerticalSeparator;","\\u2758",
  "&VerticalTilde;","\\u2240",
  "&VeryThinSpace;","\\u200A",
  "&Vfr;","\\uD835\\uDD19",
  "&Vopf;","\\uD835\\uDD4D",
  "&Vscr;","\\uD835\\uDCB1",
  "&Vvdash;","\\u22AA",
  "&Wcirc;","\\u0174",
  "&Wedge;","\\u22C0",
  "&Wfr;","\\uD835\\uDD1A",
  "&Wopf;","\\uD835\\uDD4E",
  "&Wscr;","\\uD835\\uDCB2",
  "&Xfr;","\\uD835\\uDD1B",
  "&Xi;","\\u039E",
  "&Xopf;","\\uD835\\uDD4F",
  "&Xscr;","\\uD835\\uDCB3",
  "&YAcy;","\\u042F",
  "&YIcy;","\\u0407",
  "&YUcy;","\\u042E",
  "&Yacute","\\u00DD",
  "&Yacute;","\\u00DD",
  "&Ycirc;","\\u0176",
  "&Ycy;","\\u042B",
  "&Yfr;","\\uD835\\uDD1C",
  "&Yopf;","\\uD835\\uDD50",
  "&Yscr;","\\uD835\\uDCB4",
  "&Yuml;","\\u0178",
  "&ZHcy;","\\u0416",
  "&Zacute;","\\u0179",
  "&Zcaron;","\\u017D",
  "&Zcy;","\\u0417",
  "&Zdot;","\\u017B",
  "&ZeroWidthSpace;","\\u200B",
  "&Zeta;","\\u0396",
  "&Zfr;","\\u2128",
  "&Zopf;","\\u2124",
  "&Zscr;","\\uD835\\uDCB5",
  "&aacute","\\u00E1",
  "&aacute;","\\u00E1",
  "&abreve;","\\u0103",
  "&ac;","\\u223E",
  "&acE;","\\u223E\\u0333",
  "&acd;","\\u223F",
  "&acirc","\\u00E2",
  "&acirc;","\\u00E2",
  "&acute","\\u00B4",
  "&acute;","\\u00B4",
  "&acy;","\\u0430",
  "&aelig","\\u00E6",
  "&aelig;","\\u00E6",
  "&af;","\\u2061",
  "&afr;","\\uD835\\uDD1E",
  "&agrave","\\u00E0",
  "&agrave;","\\u00E0",
  "&alefsym;","\\u2135",
  "&aleph;","\\u2135",
  "&alpha;","\\u03B1",
  "&amacr;","\\u0101",
  "&amalg;","\\u2A3F",
  "&amp","\\u0026",
  "&amp;","\\u0026",
  "&and;","\\u2227",
  "&andand;","\\u2A55",
  "&andd;","\\u2A5C",
  "&andslope;","\\u2A58",
  "&andv;","\\u2A5A",
  "&ang;","\\u2220",
  "&ange;","\\u29A4",
  "&angle;","\\u2220",
  "&angmsd;","\\u2221",
  "&angmsdaa;","\\u29A8",
  "&angmsdab;","\\u29A9",
  "&angmsdac;","\\u29AA",
  "&angmsdad;","\\u29AB",
  "&angmsdae;","\\u29AC",
  "&angmsdaf;","\\u29AD",
  "&angmsdag;","\\u29AE",
  "&angmsdah;","\\u29AF",
  "&angrt;","\\u221F",
  "&angrtvb;","\\u22BE",
  "&angrtvbd;","\\u299D",
  "&angsph;","\\u2222",
  "&angst;","\\u00C5",
  "&angzarr;","\\u237C",
  "&aogon;","\\u0105",
  "&aopf;","\\uD835\\uDD52",
  "&ap;","\\u2248",
  "&apE;","\\u2A70",
  "&apacir;","\\u2A6F",
  "&ape;","\\u224A",
  "&apid;","\\u224B",
  "&apos;","\\u0027",
  "&approx;","\\u2248",
  "&approxeq;","\\u224A",
  "&aring","\\u00E5",
  "&aring;","\\u00E5",
  "&ascr;","\\uD835\\uDCB6",
  "&ast;","\\u002A",
  "&asymp;","\\u2248",
  "&asympeq;","\\u224D",
  "&atilde","\\u00E3",
  "&atilde;","\\u00E3",
  "&auml","\\u00E4",
  "&auml;","\\u00E4",
  "&awconint;","\\u2233",
  "&awint;","\\u2A11",
  "&bNot;","\\u2AED",
  "&backcong;","\\u224C",
  "&backepsilon;","\\u03F6",
  "&backprime;","\\u2035",
  "&backsim;","\\u223D",
  "&backsimeq;","\\u22CD",
  "&barvee;","\\u22BD",
  "&barwed;","\\u2305",
  "&barwedge;","\\u2305",
  "&bbrk;","\\u23B5",
  "&bbrktbrk;","\\u23B6",
  "&bcong;","\\u224C",
  "&bcy;","\\u0431",
  "&bdquo;","\\u201E",
  "&becaus;","\\u2235",
  "&because;","\\u2235",
  "&bemptyv;","\\u29B0",
  "&bepsi;","\\u03F6",
  "&bernou;","\\u212C",
  "&beta;","\\u03B2",
  "&beth;","\\u2136",
  "&between;","\\u226C",
  "&bfr;","\\uD835\\uDD1F",
  "&bigcap;","\\u22C2",
  "&bigcirc;","\\u25EF",
  "&bigcup;","\\u22C3",
  "&bigodot;","\\u2A00",
  "&bigoplus;","\\u2A01",
  "&bigotimes;","\\u2A02",
  "&bigsqcup;","\\u2A06",
  "&bigstar;","\\u2605",
  "&bigtriangledown;","\\u25BD",
  "&bigtriangleup;","\\u25B3",
  "&biguplus;","\\u2A04",
  "&bigvee;","\\u22C1",
  "&bigwedge;","\\u22C0",
  "&bkarow;","\\u290D",
  "&blacklozenge;","\\u29EB",
  "&blacksquare;","\\u25AA",
  "&blacktriangle;","\\u25B4",
  "&blacktriangledown;","\\u25BE",
  "&blacktriangleleft;","\\u25C2",
  "&blacktriangleright;","\\u25B8",
  "&blank;","\\u2423",
  "&blk12;","\\u2592",
  "&blk14;","\\u2591",
  "&blk34;","\\u2593",
  "&block;","\\u2588",
  "&bne;","\\u003D\\u20E5",
  "&bnequiv;","\\u2261\\u20E5",
  "&bnot;","\\u2310",
  "&bopf;","\\uD835\\uDD53",
  "&bot;","\\u22A5",
  "&bottom;","\\u22A5",
  "&bowtie;","\\u22C8",
  "&boxDL;","\\u2557",
  "&boxDR;","\\u2554",
  "&boxDl;","\\u2556",
  "&boxDr;","\\u2553",
  "&boxH;","\\u2550",
  "&boxHD;","\\u2566",
  "&boxHU;","\\u2569",
  "&boxHd;","\\u2564",
  "&boxHu;","\\u2567",
  "&boxUL;","\\u255D",
  "&boxUR;","\\u255A",
  "&boxUl;","\\u255C",
  "&boxUr;","\\u2559",
  "&boxV;","\\u2551",
  "&boxVH;","\\u256C",
  "&boxVL;","\\u2563",
  "&boxVR;","\\u2560",
  "&boxVh;","\\u256B",
  "&boxVl;","\\u2562",
  "&boxVr;","\\u255F",
  "&boxbox;","\\u29C9",
  "&boxdL;","\\u2555",
  "&boxdR;","\\u2552",
  "&boxdl;","\\u2510",
  "&boxdr;","\\u250C",
  "&boxh;","\\u2500",
  "&boxhD;","\\u2565",
  "&boxhU;","\\u2568",
  "&boxhd;","\\u252C",
  "&boxhu;","\\u2534",
  "&boxminus;","\\u229F",
  "&boxplus;","\\u229E",
  "&boxtimes;","\\u22A0",
  "&boxuL;","\\u255B",
  "&boxuR;","\\u2558",
  "&boxul;","\\u2518",
  "&boxur;","\\u2514",
  "&boxv;","\\u2502",
  "&boxvH;","\\u256A",
  "&boxvL;","\\u2561",
  "&boxvR;","\\u255E",
  "&boxvh;","\\u253C",
  "&boxvl;","\\u2524",
  "&boxvr;","\\u251C",
  "&bprime;","\\u2035",
  "&breve;","\\u02D8",
  "&brvbar","\\u00A6",
  "&brvbar;","\\u00A6",
  "&bscr;","\\uD835\\uDCB7",
  "&bsemi;","\\u204F",
  "&bsim;","\\u223D",
  "&bsime;","\\u22CD",
  "&bsol;","\\u005C",
  "&bsolb;","\\u29C5",
  "&bsolhsub;","\\u27C8",
  "&bull;","\\u2022",
  "&bullet;","\\u2022",
  "&bump;","\\u224E",
  "&bumpE;","\\u2AAE",
  "&bumpe;","\\u224F",
  "&bumpeq;","\\u224F",
  "&cacute;","\\u0107",
  "&cap;","\\u2229",
  "&capand;","\\u2A44",
  "&capbrcup;","\\u2A49",
  "&capcap;","\\u2A4B",
  "&capcup;","\\u2A47",
  "&capdot;","\\u2A40",
  "&caps;","\\u2229\\uFE00",
  "&caret;","\\u2041",
  "&caron;","\\u02C7",
  "&ccaps;","\\u2A4D",
  "&ccaron;","\\u010D",
  "&ccedil","\\u00E7",
  "&ccedil;","\\u00E7",
  "&ccirc;","\\u0109",
  "&ccups;","\\u2A4C",
  "&ccupssm;","\\u2A50",
  "&cdot;","\\u010B",
  "&cedil","\\u00B8",
  "&cedil;","\\u00B8",
  "&cemptyv;","\\u29B2",
  "&cent","\\u00A2",
  "&cent;","\\u00A2",
  "&centerdot;","\\u00B7",
  "&cfr;","\\uD835\\uDD20",
  "&chcy;","\\u0447",
  "&check;","\\u2713",
  "&checkmark;","\\u2713",
  "&chi;","\\u03C7",
  "&cir;","\\u25CB",
  "&cirE;","\\u29C3",
  "&circ;","\\u02C6",
  "&circeq;","\\u2257",
  "&circlearrowleft;","\\u21BA",
  "&circlearrowright;","\\u21BB",
  "&circledR;","\\u00AE",
  "&circledS;","\\u24C8",
  "&circledast;","\\u229B",
  "&circledcirc;","\\u229A",
  "&circleddash;","\\u229D",
  "&cire;","\\u2257",
  "&cirfnint;","\\u2A10",
  "&cirmid;","\\u2AEF",
  "&cirscir;","\\u29C2",
  "&clubs;","\\u2663",
  "&clubsuit;","\\u2663",
  "&colon;","\\u003A",
  "&colone;","\\u2254",
  "&coloneq;","\\u2254",
  "&comma;","\\u002C",
  "&commat;","\\u0040",
  "&comp;","\\u2201",
  "&compfn;","\\u2218",
  "&complement;","\\u2201",
  "&complexes;","\\u2102",
  "&cong;","\\u2245",
  "&congdot;","\\u2A6D",
  "&conint;","\\u222E",
  "&copf;","\\uD835\\uDD54",
  "&coprod;","\\u2210",
  "&copy","\\u00A9",
  "&copy;","\\u00A9",
  "&copysr;","\\u2117",
  "&crarr;","\\u21B5",
  "&cross;","\\u2717",
  "&cscr;","\\uD835\\uDCB8",
  "&csub;","\\u2ACF",
  "&csube;","\\u2AD1",
  "&csup;","\\u2AD0",
  "&csupe;","\\u2AD2",
  "&ctdot;","\\u22EF",
  "&cudarrl;","\\u2938",
  "&cudarrr;","\\u2935",
  "&cuepr;","\\u22DE",
  "&cuesc;","\\u22DF",
  "&cularr;","\\u21B6",
  "&cularrp;","\\u293D",
  "&cup;","\\u222A",
  "&cupbrcap;","\\u2A48",
  "&cupcap;","\\u2A46",
  "&cupcup;","\\u2A4A",
  "&cupdot;","\\u228D",
  "&cupor;","\\u2A45",
  "&cups;","\\u222A\\uFE00",
  "&curarr;","\\u21B7",
  "&curarrm;","\\u293C",
  "&curlyeqprec;","\\u22DE",
  "&curlyeqsucc;","\\u22DF",
  "&curlyvee;","\\u22CE",
  "&curlywedge;","\\u22CF",
  "&curren","\\u00A4",
  "&curren;","\\u00A4",
  "&curvearrowleft;","\\u21B6",
  "&curvearrowright;","\\u21B7",
  "&cuvee;","\\u22CE",
  "&cuwed;","\\u22CF",
  "&cwconint;","\\u2232",
  "&cwint;","\\u2231",
  "&cylcty;","\\u232D",
  "&dArr;","\\u21D3",
  "&dHar;","\\u2965",
  "&dagger;","\\u2020",
  "&daleth;","\\u2138",
  "&darr;","\\u2193",
  "&dash;","\\u2010",
  "&dashv;","\\u22A3",
  "&dbkarow;","\\u290F",
  "&dblac;","\\u02DD",
  "&dcaron;","\\u010F",
  "&dcy;","\\u0434",
  "&dd;","\\u2146",
  "&ddagger;","\\u2021",
  "&ddarr;","\\u21CA",
  "&ddotseq;","\\u2A77",
  "&deg","\\u00B0",
  "&deg;","\\u00B0",
  "&delta;","\\u03B4",
  "&demptyv;","\\u29B1",
  "&dfisht;","\\u297F",
  "&dfr;","\\uD835\\uDD21",
  "&dharl;","\\u21C3",
  "&dharr;","\\u21C2",
  "&diam;","\\u22C4",
  "&diamond;","\\u22C4",
  "&diamondsuit;","\\u2666",
  "&diams;","\\u2666",
  "&die;","\\u00A8",
  "&digamma;","\\u03DD",
  "&disin;","\\u22F2",
  "&div;","\\u00F7",
  "&divide","\\u00F7",
  "&divide;","\\u00F7",
  "&divideontimes;","\\u22C7",
  "&divonx;","\\u22C7",
  "&djcy;","\\u0452",
  "&dlcorn;","\\u231E",
  "&dlcrop;","\\u230D",
  "&dollar;","\\u0024",
  "&dopf;","\\uD835\\uDD55",
  "&dot;","\\u02D9",
  "&doteq;","\\u2250",
  "&doteqdot;","\\u2251",
  "&dotminus;","\\u2238",
  "&dotplus;","\\u2214",
  "&dotsquare;","\\u22A1",
  "&doublebarwedge;","\\u2306",
  "&downarrow;","\\u2193",
  "&downdownarrows;","\\u21CA",
  "&downharpoonleft;","\\u21C3",
  "&downharpoonright;","\\u21C2",
  "&drbkarow;","\\u2910",
  "&drcorn;","\\u231F",
  "&drcrop;","\\u230C",
  "&dscr;","\\uD835\\uDCB9",
  "&dscy;","\\u0455",
  "&dsol;","\\u29F6",
  "&dstrok;","\\u0111",
  "&dtdot;","\\u22F1",
  "&dtri;","\\u25BF",
  "&dtrif;","\\u25BE",
  "&duarr;","\\u21F5",
  "&duhar;","\\u296F",
  "&dwangle;","\\u29A6",
  "&dzcy;","\\u045F",
  "&dzigrarr;","\\u27FF",
  "&eDDot;","\\u2A77",
  "&eDot;","\\u2251",
  "&eacute","\\u00E9",
  "&eacute;","\\u00E9",
  "&easter;","\\u2A6E",
  "&ecaron;","\\u011B",
  "&ecir;","\\u2256",
  "&ecirc","\\u00EA",
  "&ecirc;","\\u00EA",
  "&ecolon;","\\u2255",
  "&ecy;","\\u044D",
  "&edot;","\\u0117",
  "&ee;","\\u2147",
  "&efDot;","\\u2252",
  "&efr;","\\uD835\\uDD22",
  "&eg;","\\u2A9A",
  "&egrave","\\u00E8",
  "&egrave;","\\u00E8",
  "&egs;","\\u2A96",
  "&egsdot;","\\u2A98",
  "&el;","\\u2A99",
  "&elinters;","\\u23E7",
  "&ell;","\\u2113",
  "&els;","\\u2A95",
  "&elsdot;","\\u2A97",
  "&emacr;","\\u0113",
  "&empty;","\\u2205",
  "&emptyset;","\\u2205",
  "&emptyv;","\\u2205",
  "&emsp13;","\\u2004",
  "&emsp14;","\\u2005",
  "&emsp;","\\u2003",
  "&eng;","\\u014B",
  "&ensp;","\\u2002",
  "&eogon;","\\u0119",
  "&eopf;","\\uD835\\uDD56",
  "&epar;","\\u22D5",
  "&eparsl;","\\u29E3",
  "&eplus;","\\u2A71",
  "&epsi;","\\u03B5",
  "&epsilon;","\\u03B5",
  "&epsiv;","\\u03F5",
  "&eqcirc;","\\u2256",
  "&eqcolon;","\\u2255",
  "&eqsim;","\\u2242",
  "&eqslantgtr;","\\u2A96",
  "&eqslantless;","\\u2A95",
  "&equals;","\\u003D",
  "&equest;","\\u225F",
  "&equiv;","\\u2261",
  "&equivDD;","\\u2A78",
  "&eqvparsl;","\\u29E5",
  "&erDot;","\\u2253",
  "&erarr;","\\u2971",
  "&escr;","\\u212F",
  "&esdot;","\\u2250",
  "&esim;","\\u2242",
  "&eta;","\\u03B7",
  "&eth","\\u00F0",
  "&eth;","\\u00F0",
  "&euml","\\u00EB",
  "&euml;","\\u00EB",
  "&euro;","\\u20AC",
  "&excl;","\\u0021",
  "&exist;","\\u2203",
  "&expectation;","\\u2130",
  "&exponentiale;","\\u2147",
  "&fallingdotseq;","\\u2252",
  "&fcy;","\\u0444",
  "&female;","\\u2640",
  "&ffilig;","\\uFB03",
  "&fflig;","\\uFB00",
  "&ffllig;","\\uFB04",
  "&ffr;","\\uD835\\uDD23",
  "&filig;","\\uFB01",
  "&fjlig;","\\u0066\\u006A",
  "&flat;","\\u266D",
  "&fllig;","\\uFB02",
  "&fltns;","\\u25B1",
  "&fnof;","\\u0192",
  "&fopf;","\\uD835\\uDD57",
  "&forall;","\\u2200",
  "&fork;","\\u22D4",
  "&forkv;","\\u2AD9",
  "&fpartint;","\\u2A0D",
  "&frac12","\\u00BD",
  "&frac12;","\\u00BD",
  "&frac13;","\\u2153",
  "&frac14","\\u00BC",
  "&frac14;","\\u00BC",
  "&frac15;","\\u2155",
  "&frac16;","\\u2159",
  "&frac18;","\\u215B",
  "&frac23;","\\u2154",
  "&frac25;","\\u2156",
  "&frac34","\\u00BE",
  "&frac34;","\\u00BE",
  "&frac35;","\\u2157",
  "&frac38;","\\u215C",
  "&frac45;","\\u2158",
  "&frac56;","\\u215A",
  "&frac58;","\\u215D",
  "&frac78;","\\u215E",
  "&frasl;","\\u2044",
  "&frown;","\\u2322",
  "&fscr;","\\uD835\\uDCBB",
  "&gE;","\\u2267",
  "&gEl;","\\u2A8C",
  "&gacute;","\\u01F5",
  "&gamma;","\\u03B3",
  "&gammad;","\\u03DD",
  "&gap;","\\u2A86",
  "&gbreve;","\\u011F",
  "&gcirc;","\\u011D",
  "&gcy;","\\u0433",
  "&gdot;","\\u0121",
  "&ge;","\\u2265",
  "&gel;","\\u22DB",
  "&geq;","\\u2265",
  "&geqq;","\\u2267",
  "&geqslant;","\\u2A7E",
  "&ges;","\\u2A7E",
  "&gescc;","\\u2AA9",
  "&gesdot;","\\u2A80",
  "&gesdoto;","\\u2A82",
  "&gesdotol;","\\u2A84",
  "&gesl;","\\u22DB\\uFE00",
  "&gesles;","\\u2A94",
  "&gfr;","\\uD835\\uDD24",
  "&gg;","\\u226B",
  "&ggg;","\\u22D9",
  "&gimel;","\\u2137",
  "&gjcy;","\\u0453",
  "&gl;","\\u2277",
  "&glE;","\\u2A92",
  "&gla;","\\u2AA5",
  "&glj;","\\u2AA4",
  "&gnE;","\\u2269",
  "&gnap;","\\u2A8A",
  "&gnapprox;","\\u2A8A",
  "&gne;","\\u2A88",
  "&gneq;","\\u2A88",
  "&gneqq;","\\u2269",
  "&gnsim;","\\u22E7",
  "&gopf;","\\uD835\\uDD58",
  "&grave;","\\u0060",
  "&gscr;","\\u210A",
  "&gsim;","\\u2273",
  "&gsime;","\\u2A8E",
  "&gsiml;","\\u2A90",
  "&gt","\\u003E",
  "&gt;","\\u003E",
  "&gtcc;","\\u2AA7",
  "&gtcir;","\\u2A7A",
  "&gtdot;","\\u22D7",
  "&gtlPar;","\\u2995",
  "&gtquest;","\\u2A7C",
  "&gtrapprox;","\\u2A86",
  "&gtrarr;","\\u2978",
  "&gtrdot;","\\u22D7",
  "&gtreqless;","\\u22DB",
  "&gtreqqless;","\\u2A8C",
  "&gtrless;","\\u2277",
  "&gtrsim;","\\u2273",
  "&gvertneqq;","\\u2269\\uFE00",
  "&gvnE;","\\u2269\\uFE00",
  "&hArr;","\\u21D4",
  "&hairsp;","\\u200A",
  "&half;","\\u00BD",
  "&hamilt;","\\u210B",
  "&hardcy;","\\u044A",
  "&harr;","\\u2194",
  "&harrcir;","\\u2948",
  "&harrw;","\\u21AD",
  "&hbar;","\\u210F",
  "&hcirc;","\\u0125",
  "&hearts;","\\u2665",
  "&heartsuit;","\\u2665",
  "&hellip;","\\u2026",
  "&hercon;","\\u22B9",
  "&hfr;","\\uD835\\uDD25",
  "&hksearow;","\\u2925",
  "&hkswarow;","\\u2926",
  "&hoarr;","\\u21FF",
  "&homtht;","\\u223B",
  "&hookleftarrow;","\\u21A9",
  "&hookrightarrow;","\\u21AA",
  "&hopf;","\\uD835\\uDD59",
  "&horbar;","\\u2015",
  "&hscr;","\\uD835\\uDCBD",
  "&hslash;","\\u210F",
  "&hstrok;","\\u0127",
  "&hybull;","\\u2043",
  "&hyphen;","\\u2010",
  "&iacute","\\u00ED",
  "&iacute;","\\u00ED",
  "&ic;","\\u2063",
  "&icirc","\\u00EE",
  "&icirc;","\\u00EE",
  "&icy;","\\u0438",
  "&iecy;","\\u0435",
  "&iexcl","\\u00A1",
  "&iexcl;","\\u00A1",
  "&iff;","\\u21D4",
  "&ifr;","\\uD835\\uDD26",
  "&igrave","\\u00EC",
  "&igrave;","\\u00EC",
  "&ii;","\\u2148",
  "&iiiint;","\\u2A0C",
  "&iiint;","\\u222D",
  "&iinfin;","\\u29DC",
  "&iiota;","\\u2129",
  "&ijlig;","\\u0133",
  "&imacr;","\\u012B",
  "&image;","\\u2111",
  "&imagline;","\\u2110",
  "&imagpart;","\\u2111",
  "&imath;","\\u0131",
  "&imof;","\\u22B7",
  "&imped;","\\u01B5",
  "&in;","\\u2208",
  "&incare;","\\u2105",
  "&infin;","\\u221E",
  "&infintie;","\\u29DD",
  "&inodot;","\\u0131",
  "&int;","\\u222B",
  "&intcal;","\\u22BA",
  "&integers;","\\u2124",
  "&intercal;","\\u22BA",
  "&intlarhk;","\\u2A17",
  "&intprod;","\\u2A3C",
  "&iocy;","\\u0451",
  "&iogon;","\\u012F",
  "&iopf;","\\uD835\\uDD5A",
  "&iota;","\\u03B9",
  "&iprod;","\\u2A3C",
  "&iquest","\\u00BF",
  "&iquest;","\\u00BF",
  "&iscr;","\\uD835\\uDCBE",
  "&isin;","\\u2208",
  "&isinE;","\\u22F9",
  "&isindot;","\\u22F5",
  "&isins;","\\u22F4",
  "&isinsv;","\\u22F3",
  "&isinv;","\\u2208",
  "&it;","\\u2062",
  "&itilde;","\\u0129",
  "&iukcy;","\\u0456",
  "&iuml","\\u00EF",
  "&iuml;","\\u00EF",
  "&jcirc;","\\u0135",
  "&jcy;","\\u0439",
  "&jfr;","\\uD835\\uDD27",
  "&jmath;","\\u0237",
  "&jopf;","\\uD835\\uDD5B",
  "&jscr;","\\uD835\\uDCBF",
  "&jsercy;","\\u0458",
  "&jukcy;","\\u0454",
  "&kappa;","\\u03BA",
  "&kappav;","\\u03F0",
  "&kcedil;","\\u0137",
  "&kcy;","\\u043A",
  "&kfr;","\\uD835\\uDD28",
  "&kgreen;","\\u0138",
  "&khcy;","\\u0445",
  "&kjcy;","\\u045C",
  "&kopf;","\\uD835\\uDD5C",
  "&kscr;","\\uD835\\uDCC0",
  "&lAarr;","\\u21DA",
  "&lArr;","\\u21D0",
  "&lAtail;","\\u291B",
  "&lBarr;","\\u290E",
  "&lE;","\\u2266",
  "&lEg;","\\u2A8B",
  "&lHar;","\\u2962",
  "&lacute;","\\u013A",
  "&laemptyv;","\\u29B4",
  "&lagran;","\\u2112",
  "&lambda;","\\u03BB",
  "&lang;","\\u27E8",
  "&langd;","\\u2991",
  "&langle;","\\u27E8",
  "&lap;","\\u2A85",
  "&laquo","\\u00AB",
  "&laquo;","\\u00AB",
  "&larr;","\\u2190",
  "&larrb;","\\u21E4",
  "&larrbfs;","\\u291F",
  "&larrfs;","\\u291D",
  "&larrhk;","\\u21A9",
  "&larrlp;","\\u21AB",
  "&larrpl;","\\u2939",
  "&larrsim;","\\u2973",
  "&larrtl;","\\u21A2",
  "&lat;","\\u2AAB",
  "&latail;","\\u2919",
  "&late;","\\u2AAD",
  "&lates;","\\u2AAD\\uFE00",
  "&lbarr;","\\u290C",
  "&lbbrk;","\\u2772",
  "&lbrace;","\\u007B",
  "&lbrack;","\\u005B",
  "&lbrke;","\\u298B",
  "&lbrksld;","\\u298F",
  "&lbrkslu;","\\u298D",
  "&lcaron;","\\u013E",
  "&lcedil;","\\u013C",
  "&lceil;","\\u2308",
  "&lcub;","\\u007B",
  "&lcy;","\\u043B",
  "&ldca;","\\u2936",
  "&ldquo;","\\u201C",
  "&ldquor;","\\u201E",
  "&ldrdhar;","\\u2967",
  "&ldrushar;","\\u294B",
  "&ldsh;","\\u21B2",
  "&le;","\\u2264",
  "&leftarrow;","\\u2190",
  "&leftarrowtail;","\\u21A2",
  "&leftharpoondown;","\\u21BD",
  "&leftharpoonup;","\\u21BC",
  "&leftleftarrows;","\\u21C7",
  "&leftrightarrow;","\\u2194",
  "&leftrightarrows;","\\u21C6",
  "&leftrightharpoons;","\\u21CB",
  "&leftrightsquigarrow;","\\u21AD",
  "&leftthreetimes;","\\u22CB",
  "&leg;","\\u22DA",
  "&leq;","\\u2264",
  "&leqq;","\\u2266",
  "&leqslant;","\\u2A7D",
  "&les;","\\u2A7D",
  "&lescc;","\\u2AA8",
  "&lesdot;","\\u2A7F",
  "&lesdoto;","\\u2A81",
  "&lesdotor;","\\u2A83",
  "&lesg;","\\u22DA\\uFE00",
  "&lesges;","\\u2A93",
  "&lessapprox;","\\u2A85",
  "&lessdot;","\\u22D6",
  "&lesseqgtr;","\\u22DA",
  "&lesseqqgtr;","\\u2A8B",
  "&lessgtr;","\\u2276",
  "&lesssim;","\\u2272",
  "&lfisht;","\\u297C",
  "&lfloor;","\\u230A",
  "&lfr;","\\uD835\\uDD29",
  "&lg;","\\u2276",
  "&lgE;","\\u2A91",
  "&lhard;","\\u21BD",
  "&lharu;","\\u21BC",
  "&lharul;","\\u296A",
  "&lhblk;","\\u2584",
  "&ljcy;","\\u0459",
  "&ll;","\\u226A",
  "&llarr;","\\u21C7",
  "&llcorner;","\\u231E",
  "&llhard;","\\u296B",
  "&lltri;","\\u25FA",
  "&lmidot;","\\u0140",
  "&lmoust;","\\u23B0",
  "&lmoustache;","\\u23B0",
  "&lnE;","\\u2268",
  "&lnap;","\\u2A89",
  "&lnapprox;","\\u2A89",
  "&lne;","\\u2A87",
  "&lneq;","\\u2A87",
  "&lneqq;","\\u2268",
  "&lnsim;","\\u22E6",
  "&loang;","\\u27EC",
  "&loarr;","\\u21FD",
  "&lobrk;","\\u27E6",
  "&longleftarrow;","\\u27F5",
  "&longleftrightarrow;","\\u27F7",
  "&longmapsto;","\\u27FC",
  "&longrightarrow;","\\u27F6",
  "&looparrowleft;","\\u21AB",
  "&looparrowright;","\\u21AC",
  "&lopar;","\\u2985",
  "&lopf;","\\uD835\\uDD5D",
  "&loplus;","\\u2A2D",
  "&lotimes;","\\u2A34",
  "&lowast;","\\u2217",
  "&lowbar;","\\u005F",
  "&loz;","\\u25CA",
  "&lozenge;","\\u25CA",
  "&lozf;","\\u29EB",
  "&lpar;","\\u0028",
  "&lparlt;","\\u2993",
  "&lrarr;","\\u21C6",
  "&lrcorner;","\\u231F",
  "&lrhar;","\\u21CB",
  "&lrhard;","\\u296D",
  "&lrm;","\\u200E",
  "&lrtri;","\\u22BF",
  "&lsaquo;","\\u2039",
  "&lscr;","\\uD835\\uDCC1",
  "&lsh;","\\u21B0",
  "&lsim;","\\u2272",
  "&lsime;","\\u2A8D",
  "&lsimg;","\\u2A8F",
  "&lsqb;","\\u005B",
  "&lsquo;","\\u2018",
  "&lsquor;","\\u201A",
  "&lstrok;","\\u0142",
  "&lt","\\u003C",
  "&lt;","\\u003C",
  "&ltcc;","\\u2AA6",
  "&ltcir;","\\u2A79",
  "&ltdot;","\\u22D6",
  "&lthree;","\\u22CB",
  "&ltimes;","\\u22C9",
  "&ltlarr;","\\u2976",
  "&ltquest;","\\u2A7B",
  "&ltrPar;","\\u2996",
  "&ltri;","\\u25C3",
  "&ltrie;","\\u22B4",
  "&ltrif;","\\u25C2",
  "&lurdshar;","\\u294A",
  "&luruhar;","\\u2966",
  "&lvertneqq;","\\u2268\\uFE00",
  "&lvnE;","\\u2268\\uFE00",
  "&mDDot;","\\u223A",
  "&macr","\\u00AF",
  "&macr;","\\u00AF",
  "&male;","\\u2642",
  "&malt;","\\u2720",
  "&maltese;","\\u2720",
  "&map;","\\u21A6",
  "&mapsto;","\\u21A6",
  "&mapstodown;","\\u21A7",
  "&mapstoleft;","\\u21A4",
  "&mapstoup;","\\u21A5",
  "&marker;","\\u25AE",
  "&mcomma;","\\u2A29",
  "&mcy;","\\u043C",
  "&mdash;","\\u2014",
  "&measuredangle;","\\u2221",
  "&mfr;","\\uD835\\uDD2A",
  "&mho;","\\u2127",
  "&micro","\\u00B5",
  "&micro;","\\u00B5",
  "&mid;","\\u2223",
  "&midast;","\\u002A",
  "&midcir;","\\u2AF0",
  "&middot","\\u00B7",
  "&middot;","\\u00B7",
  "&minus;","\\u2212",
  "&minusb;","\\u229F",
  "&minusd;","\\u2238",
  "&minusdu;","\\u2A2A",
  "&mlcp;","\\u2ADB",
  "&mldr;","\\u2026",
  "&mnplus;","\\u2213",
  "&models;","\\u22A7",
  "&mopf;","\\uD835\\uDD5E",
  "&mp;","\\u2213",
  "&mscr;","\\uD835\\uDCC2",
  "&mstpos;","\\u223E",
  "&mu;","\\u03BC",
  "&multimap;","\\u22B8",
  "&mumap;","\\u22B8",
  "&nGg;","\\u22D9\\u0338",
  "&nGt;","\\u226B\\u20D2",
  "&nGtv;","\\u226B\\u0338",
  "&nLeftarrow;","\\u21CD",
  "&nLeftrightarrow;","\\u21CE",
  "&nLl;","\\u22D8\\u0338",
  "&nLt;","\\u226A\\u20D2",
  "&nLtv;","\\u226A\\u0338",
  "&nRightarrow;","\\u21CF",
  "&nVDash;","\\u22AF",
  "&nVdash;","\\u22AE",
  "&nabla;","\\u2207",
  "&nacute;","\\u0144",
  "&nang;","\\u2220\\u20D2",
  "&nap;","\\u2249",
  "&napE;","\\u2A70\\u0338",
  "&napid;","\\u224B\\u0338",
  "&napos;","\\u0149",
  "&napprox;","\\u2249",
  "&natur;","\\u266E",
  "&natural;","\\u266E",
  "&naturals;","\\u2115",
  "&nbsp","\\u00A0",
  "&nbsp;","\\u00A0",
  "&nbump;","\\u224E\\u0338",
  "&nbumpe;","\\u224F\\u0338",
  "&ncap;","\\u2A43",
  "&ncaron;","\\u0148",
  "&ncedil;","\\u0146",
  "&ncong;","\\u2247",
  "&ncongdot;","\\u2A6D\\u0338",
  "&ncup;","\\u2A42",
  "&ncy;","\\u043D",
  "&ndash;","\\u2013",
  "&ne;","\\u2260",
  "&neArr;","\\u21D7",
  "&nearhk;","\\u2924",
  "&nearr;","\\u2197",
  "&nearrow;","\\u2197",
  "&nedot;","\\u2250\\u0338",
  "&nequiv;","\\u2262",
  "&nesear;","\\u2928",
  "&nesim;","\\u2242\\u0338",
  "&nexist;","\\u2204",
  "&nexists;","\\u2204",
  "&nfr;","\\uD835\\uDD2B",
  "&ngE;","\\u2267\\u0338",
  "&nge;","\\u2271",
  "&ngeq;","\\u2271",
  "&ngeqq;","\\u2267\\u0338",
  "&ngeqslant;","\\u2A7E\\u0338",
  "&nges;","\\u2A7E\\u0338",
  "&ngsim;","\\u2275",
  "&ngt;","\\u226F",
  "&ngtr;","\\u226F",
  "&nhArr;","\\u21CE",
  "&nharr;","\\u21AE",
  "&nhpar;","\\u2AF2",
  "&ni;","\\u220B",
  "&nis;","\\u22FC",
  "&nisd;","\\u22FA",
  "&niv;","\\u220B",
  "&njcy;","\\u045A",
  "&nlArr;","\\u21CD",
  "&nlE;","\\u2266\\u0338",
  "&nlarr;","\\u219A",
  "&nldr;","\\u2025",
  "&nle;","\\u2270",
  "&nleftarrow;","\\u219A",
  "&nleftrightarrow;","\\u21AE",
  "&nleq;","\\u2270",
  "&nleqq;","\\u2266\\u0338",
  "&nleqslant;","\\u2A7D\\u0338",
  "&nles;","\\u2A7D\\u0338",
  "&nless;","\\u226E",
  "&nlsim;","\\u2274",
  "&nlt;","\\u226E",
  "&nltri;","\\u22EA",
  "&nltrie;","\\u22EC",
  "&nmid;","\\u2224",
  "&nopf;","\\uD835\\uDD5F",
  "&not","\\u00AC",
  "&not;","\\u00AC",
  "&notin;","\\u2209",
  "&notinE;","\\u22F9\\u0338",
  "&notindot;","\\u22F5\\u0338",
  "&notinva;","\\u2209",
  "&notinvb;","\\u22F7",
  "&notinvc;","\\u22F6",
  "&notni;","\\u220C",
  "&notniva;","\\u220C",
  "&notnivb;","\\u22FE",
  "&notnivc;","\\u22FD",
  "&npar;","\\u2226",
  "&nparallel;","\\u2226",
  "&nparsl;","\\u2AFD\\u20E5",
  "&npart;","\\u2202\\u0338",
  "&npolint;","\\u2A14",
  "&npr;","\\u2280",
  "&nprcue;","\\u22E0",
  "&npre;","\\u2AAF\\u0338",
  "&nprec;","\\u2280",
  "&npreceq;","\\u2AAF\\u0338",
  "&nrArr;","\\u21CF",
  "&nrarr;","\\u219B",
  "&nrarrc;","\\u2933\\u0338",
  "&nrarrw;","\\u219D\\u0338",
  "&nrightarrow;","\\u219B",
  "&nrtri;","\\u22EB",
  "&nrtrie;","\\u22ED",
  "&nsc;","\\u2281",
  "&nsccue;","\\u22E1",
  "&nsce;","\\u2AB0\\u0338",
  "&nscr;","\\uD835\\uDCC3",
  "&nshortmid;","\\u2224",
  "&nshortparallel;","\\u2226",
  "&nsim;","\\u2241",
  "&nsime;","\\u2244",
  "&nsimeq;","\\u2244",
  "&nsmid;","\\u2224",
  "&nspar;","\\u2226",
  "&nsqsube;","\\u22E2",
  "&nsqsupe;","\\u22E3",
  "&nsub;","\\u2284",
  "&nsubE;","\\u2AC5\\u0338",
  "&nsube;","\\u2288",
  "&nsubset;","\\u2282\\u20D2",
  "&nsubseteq;","\\u2288",
  "&nsubseteqq;","\\u2AC5\\u0338",
  "&nsucc;","\\u2281",
  "&nsucceq;","\\u2AB0\\u0338",
  "&nsup;","\\u2285",
  "&nsupE;","\\u2AC6\\u0338",
  "&nsupe;","\\u2289",
  "&nsupset;","\\u2283\\u20D2",
  "&nsupseteq;","\\u2289",
  "&nsupseteqq;","\\u2AC6\\u0338",
  "&ntgl;","\\u2279",
  "&ntilde","\\u00F1",
  "&ntilde;","\\u00F1",
  "&ntlg;","\\u2278",
  "&ntriangleleft;","\\u22EA",
  "&ntrianglelefteq;","\\u22EC",
  "&ntriangleright;","\\u22EB",
  "&ntrianglerighteq;","\\u22ED",
  "&nu;","\\u03BD",
  "&num;","\\u0023",
  "&numero;","\\u2116",
  "&numsp;","\\u2007",
  "&nvDash;","\\u22AD",
  "&nvHarr;","\\u2904",
  "&nvap;","\\u224D\\u20D2",
  "&nvdash;","\\u22AC",
  "&nvge;","\\u2265\\u20D2",
  "&nvgt;","\\u003E\\u20D2",
  "&nvinfin;","\\u29DE",
  "&nvlArr;","\\u2902",
  "&nvle;","\\u2264\\u20D2",
  "&nvlt;","\\u003C\\u20D2",
  "&nvltrie;","\\u22B4\\u20D2",
  "&nvrArr;","\\u2903",
  "&nvrtrie;","\\u22B5\\u20D2",
  "&nvsim;","\\u223C\\u20D2",
  "&nwArr;","\\u21D6",
  "&nwarhk;","\\u2923",
  "&nwarr;","\\u2196",
  "&nwarrow;","\\u2196",
  "&nwnear;","\\u2927",
  "&oS;","\\u24C8",
  "&oacute","\\u00F3",
  "&oacute;","\\u00F3",
  "&oast;","\\u229B",
  "&ocir;","\\u229A",
  "&ocirc","\\u00F4",
  "&ocirc;","\\u00F4",
  "&ocy;","\\u043E",
  "&odash;","\\u229D",
  "&odblac;","\\u0151",
  "&odiv;","\\u2A38",
  "&odot;","\\u2299",
  "&odsold;","\\u29BC",
  "&oelig;","\\u0153",
  "&ofcir;","\\u29BF",
  "&ofr;","\\uD835\\uDD2C",
  "&ogon;","\\u02DB",
  "&ograve","\\u00F2",
  "&ograve;","\\u00F2",
  "&ogt;","\\u29C1",
  "&ohbar;","\\u29B5",
  "&ohm;","\\u03A9",
  "&oint;","\\u222E",
  "&olarr;","\\u21BA",
  "&olcir;","\\u29BE",
  "&olcross;","\\u29BB",
  "&oline;","\\u203E",
  "&olt;","\\u29C0",
  "&omacr;","\\u014D",
  "&omega;","\\u03C9",
  "&omicron;","\\u03BF",
  "&omid;","\\u29B6",
  "&ominus;","\\u2296",
  "&oopf;","\\uD835\\uDD60",
  "&opar;","\\u29B7",
  "&operp;","\\u29B9",
  "&oplus;","\\u2295",
  "&or;","\\u2228",
  "&orarr;","\\u21BB",
  "&ord;","\\u2A5D",
  "&order;","\\u2134",
  "&orderof;","\\u2134",
  "&ordf","\\u00AA",
  "&ordf;","\\u00AA",
  "&ordm","\\u00BA",
  "&ordm;","\\u00BA",
  "&origof;","\\u22B6",
  "&oror;","\\u2A56",
  "&orslope;","\\u2A57",
  "&orv;","\\u2A5B",
  "&oscr;","\\u2134",
  "&oslash","\\u00F8",
  "&oslash;","\\u00F8",
  "&osol;","\\u2298",
  "&otilde","\\u00F5",
  "&otilde;","\\u00F5",
  "&otimes;","\\u2297",
  "&otimesas;","\\u2A36",
  "&ouml","\\u00F6",
  "&ouml;","\\u00F6",
  "&ovbar;","\\u233D",
  "&par;","\\u2225",
  "&para","\\u00B6",
  "&para;","\\u00B6",
  "&parallel;","\\u2225",
  "&parsim;","\\u2AF3",
  "&parsl;","\\u2AFD",
  "&part;","\\u2202",
  "&pcy;","\\u043F",
  "&percnt;","\\u0025",
  "&period;","\\u002E",
  "&permil;","\\u2030",
  "&perp;","\\u22A5",
  "&pertenk;","\\u2031",
  "&pfr;","\\uD835\\uDD2D",
  "&phi;","\\u03C6",
  "&phiv;","\\u03D5",
  "&phmmat;","\\u2133",
  "&phone;","\\u260E",
  "&pi;","\\u03C0",
  "&pitchfork;","\\u22D4",
  "&piv;","\\u03D6",
  "&planck;","\\u210F",
  "&planckh;","\\u210E",
  "&plankv;","\\u210F",
  "&plus;","\\u002B",
  "&plusacir;","\\u2A23",
  "&plusb;","\\u229E",
  "&pluscir;","\\u2A22",
  "&plusdo;","\\u2214",
  "&plusdu;","\\u2A25",
  "&pluse;","\\u2A72",
  "&plusmn","\\u00B1",
  "&plusmn;","\\u00B1",
  "&plussim;","\\u2A26",
  "&plustwo;","\\u2A27",
  "&pm;","\\u00B1",
  "&pointint;","\\u2A15",
  "&popf;","\\uD835\\uDD61",
  "&pound","\\u00A3",
  "&pound;","\\u00A3",
  "&pr;","\\u227A",
  "&prE;","\\u2AB3",
  "&prap;","\\u2AB7",
  "&prcue;","\\u227C",
  "&pre;","\\u2AAF",
  "&prec;","\\u227A",
  "&precapprox;","\\u2AB7",
  "&preccurlyeq;","\\u227C",
  "&preceq;","\\u2AAF",
  "&precnapprox;","\\u2AB9",
  "&precneqq;","\\u2AB5",
  "&precnsim;","\\u22E8",
  "&precsim;","\\u227E",
  "&prime;","\\u2032",
  "&primes;","\\u2119",
  "&prnE;","\\u2AB5",
  "&prnap;","\\u2AB9",
  "&prnsim;","\\u22E8",
  "&prod;","\\u220F",
  "&profalar;","\\u232E",
  "&profline;","\\u2312",
  "&profsurf;","\\u2313",
  "&prop;","\\u221D",
  "&propto;","\\u221D",
  "&prsim;","\\u227E",
  "&prurel;","\\u22B0",
  "&pscr;","\\uD835\\uDCC5",
  "&psi;","\\u03C8",
  "&puncsp;","\\u2008",
  "&qfr;","\\uD835\\uDD2E",
  "&qint;","\\u2A0C",
  "&qopf;","\\uD835\\uDD62",
  "&qprime;","\\u2057",
  "&qscr;","\\uD835\\uDCC6",
  "&quaternions;","\\u210D",
  "&quatint;","\\u2A16",
  "&quest;","\\u003F",
  "&questeq;","\\u225F",
  "&quot","\\u0022",
  "&quot;","\\u0022",
  "&rAarr;","\\u21DB",
  "&rArr;","\\u21D2",
  "&rAtail;","\\u291C",
  "&rBarr;","\\u290F",
  "&rHar;","\\u2964",
  "&race;","\\u223D\\u0331",
  "&racute;","\\u0155",
  "&radic;","\\u221A",
  "&raemptyv;","\\u29B3",
  "&rang;","\\u27E9",
  "&rangd;","\\u2992",
  "&range;","\\u29A5",
  "&rangle;","\\u27E9",
  "&raquo","\\u00BB",
  "&raquo;","\\u00BB",
  "&rarr;","\\u2192",
  "&rarrap;","\\u2975",
  "&rarrb;","\\u21E5",
  "&rarrbfs;","\\u2920",
  "&rarrc;","\\u2933",
  "&rarrfs;","\\u291E",
  "&rarrhk;","\\u21AA",
  "&rarrlp;","\\u21AC",
  "&rarrpl;","\\u2945",
  "&rarrsim;","\\u2974",
  "&rarrtl;","\\u21A3",
  "&rarrw;","\\u219D",
  "&ratail;","\\u291A",
  "&ratio;","\\u2236",
  "&rationals;","\\u211A",
  "&rbarr;","\\u290D",
  "&rbbrk;","\\u2773",
  "&rbrace;","\\u007D",
  "&rbrack;","\\u005D",
  "&rbrke;","\\u298C",
  "&rbrksld;","\\u298E",
  "&rbrkslu;","\\u2990",
  "&rcaron;","\\u0159",
  "&rcedil;","\\u0157",
  "&rceil;","\\u2309",
  "&rcub;","\\u007D",
  "&rcy;","\\u0440",
  "&rdca;","\\u2937",
  "&rdldhar;","\\u2969",
  "&rdquo;","\\u201D",
  "&rdquor;","\\u201D",
  "&rdsh;","\\u21B3",
  "&real;","\\u211C",
  "&realine;","\\u211B",
  "&realpart;","\\u211C",
  "&reals;","\\u211D",
  "&rect;","\\u25AD",
  "&reg","\\u00AE",
  "&reg;","\\u00AE",
  "&rfisht;","\\u297D",
  "&rfloor;","\\u230B",
  "&rfr;","\\uD835\\uDD2F",
  "&rhard;","\\u21C1",
  "&rharu;","\\u21C0",
  "&rharul;","\\u296C",
  "&rho;","\\u03C1",
  "&rhov;","\\u03F1",
  "&rightarrow;","\\u2192",
  "&rightarrowtail;","\\u21A3",
  "&rightharpoondown;","\\u21C1",
  "&rightharpoonup;","\\u21C0",
  "&rightleftarrows;","\\u21C4",
  "&rightleftharpoons;","\\u21CC",
  "&rightrightarrows;","\\u21C9",
  "&rightsquigarrow;","\\u219D",
  "&rightthreetimes;","\\u22CC",
  "&ring;","\\u02DA",
  "&risingdotseq;","\\u2253",
  "&rlarr;","\\u21C4",
  "&rlhar;","\\u21CC",
  "&rlm;","\\u200F",
  "&rmoust;","\\u23B1",
  "&rmoustache;","\\u23B1",
  "&rnmid;","\\u2AEE",
  "&roang;","\\u27ED",
  "&roarr;","\\u21FE",
  "&robrk;","\\u27E7",
  "&ropar;","\\u2986",
  "&ropf;","\\uD835\\uDD63",
  "&roplus;","\\u2A2E",
  "&rotimes;","\\u2A35",
  "&rpar;","\\u0029",
  "&rpargt;","\\u2994",
  "&rppolint;","\\u2A12",
  "&rrarr;","\\u21C9",
  "&rsaquo;","\\u203A",
  "&rscr;","\\uD835\\uDCC7",
  "&rsh;","\\u21B1",
  "&rsqb;","\\u005D",
  "&rsquo;","\\u2019",
  "&rsquor;","\\u2019",
  "&rthree;","\\u22CC",
  "&rtimes;","\\u22CA",
  "&rtri;","\\u25B9",
  "&rtrie;","\\u22B5",
  "&rtrif;","\\u25B8",
  "&rtriltri;","\\u29CE",
  "&ruluhar;","\\u2968",
  "&rx;","\\u211E",
  "&sacute;","\\u015B",
  "&sbquo;","\\u201A",
  "&sc;","\\u227B",
  "&scE;","\\u2AB4",
  "&scap;","\\u2AB8",
  "&scaron;","\\u0161",
  "&sccue;","\\u227D",
  "&sce;","\\u2AB0",
  "&scedil;","\\u015F",
  "&scirc;","\\u015D",
  "&scnE;","\\u2AB6",
  "&scnap;","\\u2ABA",
  "&scnsim;","\\u22E9",
  "&scpolint;","\\u2A13",
  "&scsim;","\\u227F",
  "&scy;","\\u0441",
  "&sdot;","\\u22C5",
  "&sdotb;","\\u22A1",
  "&sdote;","\\u2A66",
  "&seArr;","\\u21D8",
  "&searhk;","\\u2925",
  "&searr;","\\u2198",
  "&searrow;","\\u2198",
  "&sect","\\u00A7",
  "&sect;","\\u00A7",
  "&semi;","\\u003B",
  "&seswar;","\\u2929",
  "&setminus;","\\u2216",
  "&setmn;","\\u2216",
  "&sext;","\\u2736",
  "&sfr;","\\uD835\\uDD30",
  "&sfrown;","\\u2322",
  "&sharp;","\\u266F",
  "&shchcy;","\\u0449",
  "&shcy;","\\u0448",
  "&shortmid;","\\u2223",
  "&shortparallel;","\\u2225",
  "&shy","\\u00AD",
  "&shy;","\\u00AD",
  "&sigma;","\\u03C3",
  "&sigmaf;","\\u03C2",
  "&sigmav;","\\u03C2",
  "&sim;","\\u223C",
  "&simdot;","\\u2A6A",
  "&sime;","\\u2243",
  "&simeq;","\\u2243",
  "&simg;","\\u2A9E",
  "&simgE;","\\u2AA0",
  "&siml;","\\u2A9D",
  "&simlE;","\\u2A9F",
  "&simne;","\\u2246",
  "&simplus;","\\u2A24",
  "&simrarr;","\\u2972",
  "&slarr;","\\u2190",
  "&smallsetminus;","\\u2216",
  "&smashp;","\\u2A33",
  "&smeparsl;","\\u29E4",
  "&smid;","\\u2223",
  "&smile;","\\u2323",
  "&smt;","\\u2AAA",
  "&smte;","\\u2AAC",
  "&smtes;","\\u2AAC\\uFE00",
  "&softcy;","\\u044C",
  "&sol;","\\u002F",
  "&solb;","\\u29C4",
  "&solbar;","\\u233F",
  "&sopf;","\\uD835\\uDD64",
  "&spades;","\\u2660",
  "&spadesuit;","\\u2660",
  "&spar;","\\u2225",
  "&sqcap;","\\u2293",
  "&sqcaps;","\\u2293\\uFE00",
  "&sqcup;","\\u2294",
  "&sqcups;","\\u2294\\uFE00",
  "&sqsub;","\\u228F",
  "&sqsube;","\\u2291",
  "&sqsubset;","\\u228F",
  "&sqsubseteq;","\\u2291",
  "&sqsup;","\\u2290",
  "&sqsupe;","\\u2292",
  "&sqsupset;","\\u2290",
  "&sqsupseteq;","\\u2292",
  "&squ;","\\u25A1",
  "&square;","\\u25A1",
  "&squarf;","\\u25AA",
  "&squf;","\\u25AA",
  "&srarr;","\\u2192",
  "&sscr;","\\uD835\\uDCC8",
  "&ssetmn;","\\u2216",
  "&ssmile;","\\u2323",
  "&sstarf;","\\u22C6",
  "&star;","\\u2606",
  "&starf;","\\u2605",
  "&straightepsilon;","\\u03F5",
  "&straightphi;","\\u03D5",
  "&strns;","\\u00AF",
  "&sub;","\\u2282",
  "&subE;","\\u2AC5",
  "&subdot;","\\u2ABD",
  "&sube;","\\u2286",
  "&subedot;","\\u2AC3",
  "&submult;","\\u2AC1",
  "&subnE;","\\u2ACB",
  "&subne;","\\u228A",
  "&subplus;","\\u2ABF",
  "&subrarr;","\\u2979",
  "&subset;","\\u2282",
  "&subseteq;","\\u2286",
  "&subseteqq;","\\u2AC5",
  "&subsetneq;","\\u228A",
  "&subsetneqq;","\\u2ACB",
  "&subsim;","\\u2AC7",
  "&subsub;","\\u2AD5",
  "&subsup;","\\u2AD3",
  "&succ;","\\u227B",
  "&succapprox;","\\u2AB8",
  "&succcurlyeq;","\\u227D",
  "&succeq;","\\u2AB0",
  "&succnapprox;","\\u2ABA",
  "&succneqq;","\\u2AB6",
  "&succnsim;","\\u22E9",
  "&succsim;","\\u227F",
  "&sum;","\\u2211",
  "&sung;","\\u266A",
  "&sup1","\\u00B9",
  "&sup1;","\\u00B9",
  "&sup2","\\u00B2",
  "&sup2;","\\u00B2",
  "&sup3","\\u00B3",
  "&sup3;","\\u00B3",
  "&sup;","\\u2283",
  "&supE;","\\u2AC6",
  "&supdot;","\\u2ABE",
  "&supdsub;","\\u2AD8",
  "&supe;","\\u2287",
  "&supedot;","\\u2AC4",
  "&suphsol;","\\u27C9",
  "&suphsub;","\\u2AD7",
  "&suplarr;","\\u297B",
  "&supmult;","\\u2AC2",
  "&supnE;","\\u2ACC",
  "&supne;","\\u228B",
  "&supplus;","\\u2AC0",
  "&supset;","\\u2283",
  "&supseteq;","\\u2287",
  "&supseteqq;","\\u2AC6",
  "&supsetneq;","\\u228B",
  "&supsetneqq;","\\u2ACC",
  "&supsim;","\\u2AC8",
  "&supsub;","\\u2AD4",
  "&supsup;","\\u2AD6",
  "&swArr;","\\u21D9",
  "&swarhk;","\\u2926",
  "&swarr;","\\u2199",
  "&swarrow;","\\u2199",
  "&swnwar;","\\u292A",
  "&szlig","\\u00DF",
  "&szlig;","\\u00DF",
  "&target;","\\u2316",
  "&tau;","\\u03C4",
  "&tbrk;","\\u23B4",
  "&tcaron;","\\u0165",
  "&tcedil;","\\u0163",
  "&tcy;","\\u0442",
  "&tdot;","\\u20DB",
  "&telrec;","\\u2315",
  "&tfr;","\\uD835\\uDD31",
  "&there4;","\\u2234",
  "&therefore;","\\u2234",
  "&theta;","\\u03B8",
  "&thetasym;","\\u03D1",
  "&thetav;","\\u03D1",
  "&thickapprox;","\\u2248",
  "&thicksim;","\\u223C",
  "&thinsp;","\\u2009",
  "&thkap;","\\u2248",
  "&thksim;","\\u223C",
  "&thorn","\\u00FE",
  "&thorn;","\\u00FE",
  "&tilde;","\\u02DC",
  "&times","\\u00D7",
  "&times;","\\u00D7",
  "&timesb;","\\u22A0",
  "&timesbar;","\\u2A31",
  "&timesd;","\\u2A30",
  "&tint;","\\u222D",
  "&toea;","\\u2928",
  "&top;","\\u22A4",
  "&topbot;","\\u2336",
  "&topcir;","\\u2AF1",
  "&topf;","\\uD835\\uDD65",
  "&topfork;","\\u2ADA",
  "&tosa;","\\u2929",
  "&tprime;","\\u2034",
  "&trade;","\\u2122",
  "&triangle;","\\u25B5",
  "&triangledown;","\\u25BF",
  "&triangleleft;","\\u25C3",
  "&trianglelefteq;","\\u22B4",
  "&triangleq;","\\u225C",
  "&triangleright;","\\u25B9",
  "&trianglerighteq;","\\u22B5",
  "&tridot;","\\u25EC",
  "&trie;","\\u225C",
  "&triminus;","\\u2A3A",
  "&triplus;","\\u2A39",
  "&trisb;","\\u29CD",
  "&tritime;","\\u2A3B",
  "&trpezium;","\\u23E2",
  "&tscr;","\\uD835\\uDCC9",
  "&tscy;","\\u0446",
  "&tshcy;","\\u045B",
  "&tstrok;","\\u0167",
  "&twixt;","\\u226C",
  "&twoheadleftarrow;","\\u219E",
  "&twoheadrightarrow;","\\u21A0",
  "&uArr;","\\u21D1",
  "&uHar;","\\u2963",
  "&uacute","\\u00FA",
  "&uacute;","\\u00FA",
  "&uarr;","\\u2191",
  "&ubrcy;","\\u045E",
  "&ubreve;","\\u016D",
  "&ucirc","\\u00FB",
  "&ucirc;","\\u00FB",
  "&ucy;","\\u0443",
  "&udarr;","\\u21C5",
  "&udblac;","\\u0171",
  "&udhar;","\\u296E",
  "&ufisht;","\\u297E",
  "&ufr;","\\uD835\\uDD32",
  "&ugrave","\\u00F9",
  "&ugrave;","\\u00F9",
  "&uharl;","\\u21BF",
  "&uharr;","\\u21BE",
  "&uhblk;","\\u2580",
  "&ulcorn;","\\u231C",
  "&ulcorner;","\\u231C",
  "&ulcrop;","\\u230F",
  "&ultri;","\\u25F8",
  "&umacr;","\\u016B",
  "&uml","\\u00A8",
  "&uml;","\\u00A8",
  "&uogon;","\\u0173",
  "&uopf;","\\uD835\\uDD66",
  "&uparrow;","\\u2191",
  "&updownarrow;","\\u2195",
  "&upharpoonleft;","\\u21BF",
  "&upharpoonright;","\\u21BE",
  "&uplus;","\\u228E",
  "&upsi;","\\u03C5",
  "&upsih;","\\u03D2",
  "&upsilon;","\\u03C5",
  "&upuparrows;","\\u21C8",
  "&urcorn;","\\u231D",
  "&urcorner;","\\u231D",
  "&urcrop;","\\u230E",
  "&uring;","\\u016F",
  "&urtri;","\\u25F9",
  "&uscr;","\\uD835\\uDCCA",
  "&utdot;","\\u22F0",
  "&utilde;","\\u0169",
  "&utri;","\\u25B5",
  "&utrif;","\\u25B4",
  "&uuarr;","\\u21C8",
  "&uuml","\\u00FC",
  "&uuml;","\\u00FC",
  "&uwangle;","\\u29A7",
  "&vArr;","\\u21D5",
  "&vBar;","\\u2AE8",
  "&vBarv;","\\u2AE9",
  "&vDash;","\\u22A8",
  "&vangrt;","\\u299C",
  "&varepsilon;","\\u03F5",
  "&varkappa;","\\u03F0",
  "&varnothing;","\\u2205",
  "&varphi;","\\u03D5",
  "&varpi;","\\u03D6",
  "&varpropto;","\\u221D",
  "&varr;","\\u2195",
  "&varrho;","\\u03F1",
  "&varsigma;","\\u03C2",
  "&varsubsetneq;","\\u228A\\uFE00",
  "&varsubsetneqq;","\\u2ACB\\uFE00",
  "&varsupsetneq;","\\u228B\\uFE00",
  "&varsupsetneqq;","\\u2ACC\\uFE00",
  "&vartheta;","\\u03D1",
  "&vartriangleleft;","\\u22B2",
  "&vartriangleright;","\\u22B3",
  "&vcy;","\\u0432",
  "&vdash;","\\u22A2",
  "&vee;","\\u2228",
  "&veebar;","\\u22BB",
  "&veeeq;","\\u225A",
  "&vellip;","\\u22EE",
  "&verbar;","\\u007C",
  "&vert;","\\u007C",
  "&vfr;","\\uD835\\uDD33",
  "&vltri;","\\u22B2",
  "&vnsub;","\\u2282\\u20D2",
  "&vnsup;","\\u2283\\u20D2",
  "&vopf;","\\uD835\\uDD67",
  "&vprop;","\\u221D",
  "&vrtri;","\\u22B3",
  "&vscr;","\\uD835\\uDCCB",
  "&vsubnE;","\\u2ACB\\uFE00",
  "&vsubne;","\\u228A\\uFE00",
  "&vsupnE;","\\u2ACC\\uFE00",
  "&vsupne;","\\u228B\\uFE00",
  "&vzigzag;","\\u299A",
  "&wcirc;","\\u0175",
  "&wedbar;","\\u2A5F",
  "&wedge;","\\u2227",
  "&wedgeq;","\\u2259",
  "&weierp;","\\u2118",
  "&wfr;","\\uD835\\uDD34",
  "&wopf;","\\uD835\\uDD68",
  "&wp;","\\u2118",
  "&wr;","\\u2240",
  "&wreath;","\\u2240",
  "&wscr;","\\uD835\\uDCCC",
  "&xcap;","\\u22C2",
  "&xcirc;","\\u25EF",
  "&xcup;","\\u22C3",
  "&xdtri;","\\u25BD",
  "&xfr;","\\uD835\\uDD35",
  "&xhArr;","\\u27FA",
  "&xharr;","\\u27F7",
  "&xi;","\\u03BE",
  "&xlArr;","\\u27F8",
  "&xlarr;","\\u27F5",
  "&xmap;","\\u27FC",
  "&xnis;","\\u22FB",
  "&xodot;","\\u2A00",
  "&xopf;","\\uD835\\uDD69",
  "&xoplus;","\\u2A01",
  "&xotime;","\\u2A02",
  "&xrArr;","\\u27F9",
  "&xrarr;","\\u27F6",
  "&xscr;","\\uD835\\uDCCD",
  "&xsqcup;","\\u2A06",
  "&xuplus;","\\u2A04",
  "&xutri;","\\u25B3",
  "&xvee;","\\u22C1",
  "&xwedge;","\\u22C0",
  "&yacute","\\u00FD",
  "&yacute;","\\u00FD",
  "&yacy;","\\u044F",
  "&ycirc;","\\u0177",
  "&ycy;","\\u044B",
  "&yen","\\u00A5",
  "&yen;","\\u00A5",
  "&yfr;","\\uD835\\uDD36",
  "&yicy;","\\u0457",
  "&yopf;","\\uD835\\uDD6A",
  "&yscr;","\\uD835\\uDCCE",
  "&yucy;","\\u044E",
  "&yuml","\\u00FF",
  "&yuml;","\\u00FF",
  "&zacute;","\\u017A",
  "&zcaron;","\\u017E",
  "&zcy;","\\u0437",
  "&zdot;","\\u017C",
  "&zeetrf;","\\u2128",
  "&zeta;","\\u03B6",
  "&zfr;","\\uD835\\uDD37",
  "&zhcy;","\\u0436",
  "&zigrarr;","\\u21DD",
  "&zopf;","\\uD835\\uDD6B",
  "&zscr;","\\uD835\\uDCCF",
  "&zwj;","\\u200D",
  "&zwnj;","\\u200C",
  NULL,NULL
};

void MKstate::setup_entities_json_to_c()
{
  entities_json_to_c_.set(entities_json_to_c_g_);
  is_setup_entities_json_to_c_=1;
}

/*
 *  FIPS-180-1 compliant SHA-1 implementation
 *
 *  Copyright (C) 2006-2009, Paul Bakker <polarssl_maintainer at polarssl.org>
 *  All rights reserved.
 *
 *  Joined copyright on original XySSL code with: Christophe Devine
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */
/*
 *  The SHA-1 standard was published by NIST in 1993.
 *
 *  http://www.itl.nist.gov/fipspubs/fip180-1.htm
 */

/**
 * \brief          SHA-1 context structure
 */
typedef struct
{
    unsigned long total[2];     /*!< number of bytes processed  */
    unsigned long state[5];     /*!< intermediate digest state  */
    unsigned char buffer[64];   /*!< data block being processed */

    unsigned char ipad[64];     /*!< HMAC: inner padding        */
    unsigned char opad[64];     /*!< HMAC: outer padding        */
}
sha1_context;

/**
 * \brief          SHA-1 context setup
 *
 * \param ctx      context to be initialized
 */
void sha1_starts( sha1_context *ctx );

/**
 * \brief          SHA-1 process buffer
 *
 * \param ctx      SHA-1 context
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 */
void sha1_update( sha1_context *ctx, unsigned char *input, int ilen );

/**
 * \brief          SHA-1 final digest
 *
 * \param ctx      SHA-1 context
 * \param output   SHA-1 checksum result
 */
void sha1_finish( sha1_context *ctx, unsigned char output[20] );

/**
 * \brief          Output = SHA-1( input buffer )
 *
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 * \param output   SHA-1 checksum result
 */
void sha1( unsigned char *input, int ilen, unsigned char output[20] );

/**
 * \brief          Output = SHA-1( file contents )
 *
 * \param path     input file name
 * \param output   SHA-1 checksum result
 *
 * \return         0 if successful, 1 if fopen failed,
 *                 or 2 if fread failed
 */
int sha1_file( char *path, unsigned char output[20] );

/**
 * \brief          SHA-1 HMAC context setup
 *
 * \param ctx      HMAC context to be initialized
 * \param key      HMAC secret key
 * \param keylen   length of the HMAC key
 */
void sha1_hmac_starts( sha1_context *ctx, unsigned char *key, int keylen );

/**
 * \brief          SHA-1 HMAC process buffer
 *
 * \param ctx      HMAC context
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 */
void sha1_hmac_update( sha1_context *ctx, unsigned char *input, int ilen );

/**
 * \brief          SHA-1 HMAC final digest
 *
 * \param ctx      HMAC context
 * \param output   SHA-1 HMAC checksum result
 */
void sha1_hmac_finish( sha1_context *ctx, unsigned char output[20] );

/**
 * \brief          Output = HMAC-SHA-1( hmac key, input buffer )
 *
 * \param key      HMAC secret key
 * \param keylen   length of the HMAC key
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 * \param output   HMAC-SHA-1 result
 */
void sha1_hmac( unsigned char *key, int keylen,
                unsigned char *input, int ilen,
                unsigned char output[20] );

/**
 * \brief          Checkup routine
 *
 * \return         0 if successful, or 1 if the test failed
 */
int sha1_self_test( int verbose );

/*
 * 32-bit integer manipulation macros (big endian)
 */

#ifndef GET_ULONG_BE
#define GET_ULONG_BE(n,b,i)                             \
{                                                       \
    (n) = ( (unsigned long) (b)[(i)    ] << 24 )        \
        | ( (unsigned long) (b)[(i) + 1] << 16 )        \
        | ( (unsigned long) (b)[(i) + 2] <<  8 )        \
        | ( (unsigned long) (b)[(i) + 3]       );       \
}
#endif

#ifndef PUT_ULONG_BE
#define PUT_ULONG_BE(n,b,i)                             \
{                                                       \
    (b)[(i)    ] = (unsigned char) ( (n) >> 24 );       \
    (b)[(i) + 1] = (unsigned char) ( (n) >> 16 );       \
    (b)[(i) + 2] = (unsigned char) ( (n) >>  8 );       \
    (b)[(i) + 3] = (unsigned char) ( (n)       );       \
}
#endif

/*
 * SHA-1 context setup
 */
void sha1_starts( sha1_context *ctx )
{
    ctx->total[0] = 0;
    ctx->total[1] = 0;

    ctx->state[0] = 0x67452301;
    ctx->state[1] = 0xEFCDAB89;
    ctx->state[2] = 0x98BADCFE;
    ctx->state[3] = 0x10325476;
    ctx->state[4] = 0xC3D2E1F0;
}

static void sha1_process( sha1_context *ctx, unsigned char data[64] )
{
    unsigned long temp, W[16], A, B, C, D, E;

    GET_ULONG_BE( W[ 0], data,  0 );
    GET_ULONG_BE( W[ 1], data,  4 );
    GET_ULONG_BE( W[ 2], data,  8 );
    GET_ULONG_BE( W[ 3], data, 12 );
    GET_ULONG_BE( W[ 4], data, 16 );
    GET_ULONG_BE( W[ 5], data, 20 );
    GET_ULONG_BE( W[ 6], data, 24 );
    GET_ULONG_BE( W[ 7], data, 28 );
    GET_ULONG_BE( W[ 8], data, 32 );
    GET_ULONG_BE( W[ 9], data, 36 );
    GET_ULONG_BE( W[10], data, 40 );
    GET_ULONG_BE( W[11], data, 44 );
    GET_ULONG_BE( W[12], data, 48 );
    GET_ULONG_BE( W[13], data, 52 );
    GET_ULONG_BE( W[14], data, 56 );
    GET_ULONG_BE( W[15], data, 60 );

#define S(x,n) ((x << n) | ((x & 0xFFFFFFFF) >> (32 - n)))

#define R(t)                                            \
(                                                       \
    temp = W[(t -  3) & 0x0F] ^ W[(t - 8) & 0x0F] ^     \
           W[(t - 14) & 0x0F] ^ W[ t      & 0x0F],      \
    ( W[t & 0x0F] = S(temp,1) )                         \
)

#define P(a,b,c,d,e,x)                                  \
{                                                       \
    e += S(a,5) + F(b,c,d) + K + x; b = S(b,30);        \
}

    A = ctx->state[0];
    B = ctx->state[1];
    C = ctx->state[2];
    D = ctx->state[3];
    E = ctx->state[4];

#define F(x,y,z) (z ^ (x & (y ^ z)))
#define K 0x5A827999

    P( A, B, C, D, E, W[0]  );
    P( E, A, B, C, D, W[1]  );
    P( D, E, A, B, C, W[2]  );
    P( C, D, E, A, B, W[3]  );
    P( B, C, D, E, A, W[4]  );
    P( A, B, C, D, E, W[5]  );
    P( E, A, B, C, D, W[6]  );
    P( D, E, A, B, C, W[7]  );
    P( C, D, E, A, B, W[8]  );
    P( B, C, D, E, A, W[9]  );
    P( A, B, C, D, E, W[10] );
    P( E, A, B, C, D, W[11] );
    P( D, E, A, B, C, W[12] );
    P( C, D, E, A, B, W[13] );
    P( B, C, D, E, A, W[14] );
    P( A, B, C, D, E, W[15] );
    P( E, A, B, C, D, R(16) );
    P( D, E, A, B, C, R(17) );
    P( C, D, E, A, B, R(18) );
    P( B, C, D, E, A, R(19) );

#undef K
#undef F

#define F(x,y,z) (x ^ y ^ z)
#define K 0x6ED9EBA1

    P( A, B, C, D, E, R(20) );
    P( E, A, B, C, D, R(21) );
    P( D, E, A, B, C, R(22) );
    P( C, D, E, A, B, R(23) );
    P( B, C, D, E, A, R(24) );
    P( A, B, C, D, E, R(25) );
    P( E, A, B, C, D, R(26) );
    P( D, E, A, B, C, R(27) );
    P( C, D, E, A, B, R(28) );
    P( B, C, D, E, A, R(29) );
    P( A, B, C, D, E, R(30) );
    P( E, A, B, C, D, R(31) );
    P( D, E, A, B, C, R(32) );
    P( C, D, E, A, B, R(33) );
    P( B, C, D, E, A, R(34) );
    P( A, B, C, D, E, R(35) );
    P( E, A, B, C, D, R(36) );
    P( D, E, A, B, C, R(37) );
    P( C, D, E, A, B, R(38) );
    P( B, C, D, E, A, R(39) );

#undef K
#undef F

#define F(x,y,z) ((x & y) | (z & (x | y)))
#define K 0x8F1BBCDC

    P( A, B, C, D, E, R(40) );
    P( E, A, B, C, D, R(41) );
    P( D, E, A, B, C, R(42) );
    P( C, D, E, A, B, R(43) );
    P( B, C, D, E, A, R(44) );
    P( A, B, C, D, E, R(45) );
    P( E, A, B, C, D, R(46) );
    P( D, E, A, B, C, R(47) );
    P( C, D, E, A, B, R(48) );
    P( B, C, D, E, A, R(49) );
    P( A, B, C, D, E, R(50) );
    P( E, A, B, C, D, R(51) );
    P( D, E, A, B, C, R(52) );
    P( C, D, E, A, B, R(53) );
    P( B, C, D, E, A, R(54) );
    P( A, B, C, D, E, R(55) );
    P( E, A, B, C, D, R(56) );
    P( D, E, A, B, C, R(57) );
    P( C, D, E, A, B, R(58) );
    P( B, C, D, E, A, R(59) );

#undef K
#undef F

#define F(x,y,z) (x ^ y ^ z)
#define K 0xCA62C1D6

    P( A, B, C, D, E, R(60) );
    P( E, A, B, C, D, R(61) );
    P( D, E, A, B, C, R(62) );
    P( C, D, E, A, B, R(63) );
    P( B, C, D, E, A, R(64) );
    P( A, B, C, D, E, R(65) );
    P( E, A, B, C, D, R(66) );
    P( D, E, A, B, C, R(67) );
    P( C, D, E, A, B, R(68) );
    P( B, C, D, E, A, R(69) );
    P( A, B, C, D, E, R(70) );
    P( E, A, B, C, D, R(71) );
    P( D, E, A, B, C, R(72) );
    P( C, D, E, A, B, R(73) );
    P( B, C, D, E, A, R(74) );
    P( A, B, C, D, E, R(75) );
    P( E, A, B, C, D, R(76) );
    P( D, E, A, B, C, R(77) );
    P( C, D, E, A, B, R(78) );
    P( B, C, D, E, A, R(79) );

#undef K
#undef F

    ctx->state[0] += A;
    ctx->state[1] += B;
    ctx->state[2] += C;
    ctx->state[3] += D;
    ctx->state[4] += E;
}

/*
 * SHA-1 process buffer
 */
void sha1_update( sha1_context *ctx, unsigned char *input, int ilen )
{
    int fill;
    unsigned long left;

    if( ilen <= 0 )
        return;

    left = ctx->total[0] & 0x3F;
    fill = 64 - left;

    ctx->total[0] += ilen;
    ctx->total[0] &= 0xFFFFFFFF;

    if( ctx->total[0] < (unsigned long) ilen )
        ctx->total[1]++;

    if( left && ilen >= fill )
    {
        memcpy( (void *) (ctx->buffer + left),
                (void *) input, fill );
        sha1_process( ctx, ctx->buffer );
        input += fill;
        ilen  -= fill;
        left = 0;
    }

    while( ilen >= 64 )
    {
        sha1_process( ctx, input );
        input += 64;
        ilen  -= 64;
    }

    if( ilen > 0 )
    {
        memcpy( (void *) (ctx->buffer + left),
                (void *) input, ilen );
    }
}

static const unsigned char sha1_padding[64] =
{
 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

/*
 * SHA-1 final digest
 */
void sha1_finish( sha1_context *ctx, unsigned char output[20] )
{
    unsigned long last, padn;
    unsigned long high, low;
    unsigned char msglen[8];

    high = ( ctx->total[0] >> 29 )
         | ( ctx->total[1] <<  3 );
    low  = ( ctx->total[0] <<  3 );

    PUT_ULONG_BE( high, msglen, 0 );
    PUT_ULONG_BE( low,  msglen, 4 );

    last = ctx->total[0] & 0x3F;
    padn = ( last < 56 ) ? ( 56 - last ) : ( 120 - last );

    sha1_update( ctx, (unsigned char *) sha1_padding, padn );
    sha1_update( ctx, msglen, 8 );

    PUT_ULONG_BE( ctx->state[0], output,  0 );
    PUT_ULONG_BE( ctx->state[1], output,  4 );
    PUT_ULONG_BE( ctx->state[2], output,  8 );
    PUT_ULONG_BE( ctx->state[3], output, 12 );
    PUT_ULONG_BE( ctx->state[4], output, 16 );
}

/*
 * output = SHA-1( input buffer )
 */
void sha1( unsigned char *input, int ilen, unsigned char output[20] )
{
    sha1_context ctx;

    sha1_starts( &ctx );
    sha1_update( &ctx, input, ilen );
    sha1_finish( &ctx, output );

    memset( &ctx, 0, sizeof( sha1_context ) );
}

/*
 * output = SHA-1( file contents )
 */
int sha1_file( char *path, unsigned char output[20] )
{
    FILE *f;
    size_t n;
    sha1_context ctx;
    unsigned char buf[1024];

    if( ( f = fopen( path, "rb" ) ) == NULL )
        return( 1 );

    sha1_starts( &ctx );

    while( ( n = fread( buf, 1, sizeof( buf ), f ) ) > 0 )
        sha1_update( &ctx, buf, (int) n );

    sha1_finish( &ctx, output );

    memset( &ctx, 0, sizeof( sha1_context ) );

    if( ferror( f ) != 0 )
    {
        fclose( f );
        return( 2 );
    }

    fclose( f );
    return( 0 );
}

/*
 * SHA-1 HMAC context setup
 */
void sha1_hmac_starts( sha1_context *ctx, unsigned char *key, int keylen )
{
    int i;
    unsigned char sum[20];

    if( keylen > 64 )
    {
        sha1( key, keylen, sum );
        keylen = 20;
        key = sum;
    }

    memset( ctx->ipad, 0x36, 64 );
    memset( ctx->opad, 0x5C, 64 );

    for( i = 0; i < keylen; i++ )
    {
        ctx->ipad[i] = (unsigned char)( ctx->ipad[i] ^ key[i] );
        ctx->opad[i] = (unsigned char)( ctx->opad[i] ^ key[i] );
    }

    sha1_starts( ctx );
    sha1_update( ctx, ctx->ipad, 64 );

    memset( sum, 0, sizeof( sum ) );
}

/*
 * SHA-1 HMAC process buffer
 */
void sha1_hmac_update( sha1_context *ctx, unsigned char *input, int ilen )
{
    sha1_update( ctx, input, ilen );
}

/*
 * SHA-1 HMAC final digest
 */
void sha1_hmac_finish( sha1_context *ctx, unsigned char output[20] )
{
    unsigned char tmpbuf[20];

    sha1_finish( ctx, tmpbuf );
    sha1_starts( ctx );
    sha1_update( ctx, ctx->opad, 64 );
    sha1_update( ctx, tmpbuf, 20 );
    sha1_finish( ctx, output );

    memset( tmpbuf, 0, sizeof( tmpbuf ) );
}

/*
 * output = HMAC-SHA-1( hmac key, input buffer )
 */
void sha1_hmac( unsigned char *key, int keylen,
                unsigned char *input, int ilen,
                unsigned char output[20] )
{
    sha1_context ctx;

    sha1_hmac_starts( &ctx, key, keylen );
    sha1_hmac_update( &ctx, input, ilen );
    sha1_hmac_finish( &ctx, output );

    memset( &ctx, 0, sizeof( sha1_context ) );
}

#if defined(POLARSSL_SELF_TEST)
/*
 * FIPS-180-1 test vectors
 */
static unsigned char sha1_test_buf[3][57] = 
{
    { "abc" },
    { "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" },
    { "" }
};

static const int sha1_test_buflen[3] =
{
    3, 56, 1000
};

static const unsigned char sha1_test_sum[3][20] =
{
    { 0xA9, 0x99, 0x3E, 0x36, 0x47, 0x06, 0x81, 0x6A, 0xBA, 0x3E,
      0x25, 0x71, 0x78, 0x50, 0xC2, 0x6C, 0x9C, 0xD0, 0xD8, 0x9D },
    { 0x84, 0x98, 0x3E, 0x44, 0x1C, 0x3B, 0xD2, 0x6E, 0xBA, 0xAE,
      0x4A, 0xA1, 0xF9, 0x51, 0x29, 0xE5, 0xE5, 0x46, 0x70, 0xF1 },
    { 0x34, 0xAA, 0x97, 0x3C, 0xD4, 0xC4, 0xDA, 0xA4, 0xF6, 0x1E,
      0xEB, 0x2B, 0xDB, 0xAD, 0x27, 0x31, 0x65, 0x34, 0x01, 0x6F }
};

/*
 * RFC 2202 test vectors
 */
static unsigned char sha1_hmac_test_key[7][26] =
{
    { "\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B\x0B"
      "\x0B\x0B\x0B\x0B" },
    { "Jefe" },
    { "\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA"
      "\xAA\xAA\xAA\xAA" },
    { "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10"
      "\x11\x12\x13\x14\x15\x16\x17\x18\x19" },
    { "\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C"
      "\x0C\x0C\x0C\x0C" },
    { "" }, /* 0xAA 80 times */
    { "" }
};

static const int sha1_hmac_test_keylen[7] =
{
    20, 4, 20, 25, 20, 80, 80
};

static unsigned char sha1_hmac_test_buf[7][74] =
{
    { "Hi There" },
    { "what do ya want for nothing?" },
    { "\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD"
      "\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD"
      "\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD"
      "\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD"
      "\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD\xDD" },
    { "\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD"
      "\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD"
      "\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD"
      "\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD"
      "\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD" },
    { "Test With Truncation" },
    { "Test Using Larger Than Block-Size Key - Hash Key First" },
    { "Test Using Larger Than Block-Size Key and Larger"
      " Than One Block-Size Data" }
};

static const int sha1_hmac_test_buflen[7] =
{
    8, 28, 50, 50, 20, 54, 73
};

static const unsigned char sha1_hmac_test_sum[7][20] =
{
    { 0xB6, 0x17, 0x31, 0x86, 0x55, 0x05, 0x72, 0x64, 0xE2, 0x8B,
      0xC0, 0xB6, 0xFB, 0x37, 0x8C, 0x8E, 0xF1, 0x46, 0xBE, 0x00 },
    { 0xEF, 0xFC, 0xDF, 0x6A, 0xE5, 0xEB, 0x2F, 0xA2, 0xD2, 0x74,
      0x16, 0xD5, 0xF1, 0x84, 0xDF, 0x9C, 0x25, 0x9A, 0x7C, 0x79 },
    { 0x12, 0x5D, 0x73, 0x42, 0xB9, 0xAC, 0x11, 0xCD, 0x91, 0xA3,
      0x9A, 0xF4, 0x8A, 0xA1, 0x7B, 0x4F, 0x63, 0xF1, 0x75, 0xD3 },
    { 0x4C, 0x90, 0x07, 0xF4, 0x02, 0x62, 0x50, 0xC6, 0xBC, 0x84,
      0x14, 0xF9, 0xBF, 0x50, 0xC8, 0x6C, 0x2D, 0x72, 0x35, 0xDA },
    { 0x4C, 0x1A, 0x03, 0x42, 0x4B, 0x55, 0xE0, 0x7F, 0xE7, 0xF2,
      0x7B, 0xE1 },
    { 0xAA, 0x4A, 0xE5, 0xE1, 0x52, 0x72, 0xD0, 0x0E, 0x95, 0x70,
      0x56, 0x37, 0xCE, 0x8A, 0x3B, 0x55, 0xED, 0x40, 0x21, 0x12 },
    { 0xE8, 0xE9, 0x9D, 0x0F, 0x45, 0x23, 0x7D, 0x78, 0x6D, 0x6B,
      0xBA, 0xA7, 0x96, 0x5C, 0x78, 0x08, 0xBB, 0xFF, 0x1A, 0x91 }
};

/*
 * Checkup routine
 */
int sha1_self_test( int verbose )
{
    int i, j, buflen;
    unsigned char buf[1024];
    unsigned char sha1sum[20];
    sha1_context ctx;

    /*
     * SHA-1
     */
    for( i = 0; i < 3; i++ )
    {
        if( verbose != 0 )
            printf( "  SHA-1 test #%d: ", i + 1 );

        sha1_starts( &ctx );

        if( i == 2 )
        {
            memset( buf, 'a', buflen = 1000 );

            for( j = 0; j < 1000; j++ )
                sha1_update( &ctx, buf, buflen );
        }
        else
            sha1_update( &ctx, sha1_test_buf[i],
                               sha1_test_buflen[i] );

        sha1_finish( &ctx, sha1sum );

        if( memcmp( sha1sum, sha1_test_sum[i], 20 ) != 0 )
        {
            if( verbose != 0 )
                printf( "failed\n" );

            return( 1 );
        }

        if( verbose != 0 )
            printf( "passed\n" );
    }

    if( verbose != 0 )
        printf( "\n" );

    for( i = 0; i < 7; i++ )
    {
        if( verbose != 0 )
            printf( "  HMAC-SHA-1 test #%d: ", i + 1 );

        if( i == 5 || i == 6 )
        {
            memset( buf, '\xAA', buflen = 80 );
            sha1_hmac_starts( &ctx, buf, buflen );
        }
        else
            sha1_hmac_starts( &ctx, sha1_hmac_test_key[i],
                                    sha1_hmac_test_keylen[i] );

        sha1_hmac_update( &ctx, sha1_hmac_test_buf[i],
                                sha1_hmac_test_buflen[i] );

        sha1_hmac_finish( &ctx, sha1sum );

        buflen = ( i == 4 ) ? 12 : 20;

        if( memcmp( sha1sum, sha1_hmac_test_sum[i], buflen ) != 0 )
        {
            if( verbose != 0 )
                printf( "failed\n" );

            return( 1 );
        }

        if( verbose != 0 )
            printf( "passed\n" );
    }

    if( verbose != 0 )
        printf( "\n" );

    return( 0 );
}

#endif
  
