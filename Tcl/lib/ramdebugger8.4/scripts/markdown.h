#ifndef MARKDOWN_H
#define MARKDOWN_H
  
#include "mytsvec.h"
  
const char* const ASCII_space_g_=" \t\r\v\f\n";
// Unicode Character 'NO-BREAK SPACE' \u00a0 - \xc2\xa0
const char* const Unicode_space_g_=" \t\r\v\f\n\xc2\xa0";
const char* const ASCII_punctuation_g_="!\"#$%&'()*+,-./(U+0021–2F):;<=>?@[\\]^_`{|}~";
const char* const ASCII_punctuation_SP_g_="!\"#$%&'()*+,-./(U+0021–2F):;<=>?@[\\]^_`{|}~ \t\r\n";

typedef enum class MK {
  none,
  document,
  paragraph,
  thematic_break,
  ATX_heading,
  setext_heading,
  indented_code_block,
  fenced_code_block,
  HTML_block,
  link_reference_definition,
  block_quote,
  list_item,
  
  code_span,
  emphasis,
  image,
  link,
  autolink,
  html,
  
  metadata_block,
  implicit_figures,
  definition_lists,
  pipe_table
  
} MarkdownStates;

inline int is_heading(MarkdownStates s){
  return s==MK::ATX_heading || s==MK::setext_heading; }

inline int is_link_image(MarkdownStates s){
  return s==MK::link || s==MK::image; }

const char* const MarkdownStates_g_[]={"none","document","paragraph",
    "thematic_break","ATX_heading",
    "setext_heading","indented_code_block","fenced_code_block","HTML_block",
    "link_reference_definition","block_quote","list_item",
    
    "code_span","emphasis","image","link","autolink","html",
    
    "metadata_block","implicit_figures","definition_lists","pipe_table",NULL};

typedef enum class OT {
  unknown,
  html,
  rdinfo,
} MarkdownOutputType;

const char* const MarkdownOutputType_g_[]={"unknown","html","rdinfo",NULL};

inline int is_container(MarkdownStates mstate)
{
  return mstate==MK::block_quote || mstate==MK::list_item;
}

inline int is_code_block(MarkdownStates mstate)
{
  return mstate==MK::indented_code_block || mstate==MK::fenced_code_block;
}

typedef enum class EXT {
  none,
  all,
  full_html,
  metadata_block,
  implicit_figures,
  link_attributes,
  definition_lists,
  numbering,
  hide_svgml,
  smart,
  pipe_tables,
  superscript,
  subscript,
  tex_math_dollars
} MarkdownExtensions;

const char* const MarkdownExtensions_g_[]={"none","all","full_html","metadata_block",
    "implicit_figures","link_attributes","definition_lists","numbering",
    "hide_svgml","smart","pipe_tables","superscript","subscript",
    "tex_math_dollars",NULL};

typedef enum class OPO {
  none=0,
  endline_to_space=1,
  no_backslash_escapes=2
} OutputParaOpts;

class MKlink
{
  public:
  MyTSchar name_,url_,title_;
  int ibox_;
};

class MKid
{
  public:
  void set(int ibox){ int ibox_=ibox; }
  int ibox_;
  MyTSchar number_;
};

class MKinline
{
  public:
  MKinline():start_(-1),end_(-1),len0_(-1),i_alt_(-1),can_start_(-1),can_end_(-1){}
  void set(MarkdownStates type,int start,int len){ type_=type; start_=start; len_=len; }
  void set(MarkdownStates type,int start,int end,int len){ type_=type; 
    start_=start; end_=end; len_=len; }
  
  MarkdownStates type_;
  int start_,end_,len0_,len_,i_alt_;
  int can_start_,can_end_;
};

class MKblocks
{
  public:
  MKblocks(): parent_(-1),open_(1),level_(0),tight_(1),number_(0) {}
  
  void set(MarkdownStates mtype,int parent){ mtype_=mtype; parent_=parent; }
  void set(MarkdownStates mtype,IntVector2D pos,IntVector2D posNoBlank,
    IntVector2D blanks,int parent){
    mtype_=mtype; pos_=pos; posNoBlank_=posNoBlank; blanks_=blanks; parent_=parent;
  }
  void nprint(int iblock,MyTSvec<MKblocks,100>& blocks,
    MyTSchar& buffer,MyTSchar& deb);
  void print_yaml(int iblock,MyTSvec<MKblocks,100>& blocks,
    MyTSchar& buffer,MyTSchar& deb);
  
  MarkdownStates mtype_;
  
//################################################################################
//    pos[0]: start of string
//    pos[1]: last character of string
//    posNoBlank[0]: start of string excluding blanks or prefixes
//    posNoBlank[1]: last character of string excluding blanks at the end
//    blanks_: number of spaces or equivalent at start or end of string
//################################################################################
  
  IntVector2D pos_,posNoBlank_,blanks_;
  int parent_,open_,level_,tight_,number_;
  MyTSint6 children_;
};

class MKstate
{
  public:
  
  MKstate(MarkdownOutputType otype):pos_(0),is_setup_entities_json_to_c_(),
    otype_(otype),buffer_(NULL),heading_numbersS_(0),image_numbers_(0),
    table_numbers_(0),formula_numbers_(0),
    lineNum_(-1),lineNum_pos_(-1){
    this->reset_line();
    active_extensions_.set(ggclong(EXT::all),1);
  }
  void set_extensions(MyTScharList& extensions);
  void reset_line(){
    SE_line_.set(-1); SE_lineNoBlank_.set(-1); blanks_line_.set(0);
  }
  MKblocks& append_block(MarkdownStates mtype_){
    blocks_.incr_num().set(mtype_,this->give_parent());
    open_blocks_.append(blocks_.num()-1);
    if(blocks_.num()>1){
      blocks_[this->give_parent()].children_.append(blocks_.num()-1);
    }
    return blocks_[end_MTS];
  }
  MKblocks& append_block(MarkdownStates mtype_,IntVector2D pos,IntVector2D posNoBlank,
    IntVector2D blanks){
    int parent=this->give_parent();
    blocks_.incr_num().set(mtype_,pos,posNoBlank,blanks,parent);
    open_blocks_.append(blocks_.num()-1);
    blocks_[parent].children_.append(blocks_.num()-1);
    return blocks_[end_MTS];
  }
  int give_parent(){
    for(int i=open_blocks_.num()-1;i>=0;i--){
      if(is_container(blocks_[open_blocks_[i]].mtype_)) return open_blocks_[i];
    }
    return 0;
  }

  void curr_close(){
    blocks_[open_blocks_[end_MTS]].open_=0;
    open_blocks_.decr_num();
  }
  void close_all(){
    for(int i=open_blocks_.num()-1;i>0;i--){
      blocks_[open_blocks_[i]].open_=0;
    }
    open_blocks_.set_num(1);
  }
  MarkdownStates give_type(int level){
    if(level<0) return MK::none;
    if(open_blocks_.num()>level) return blocks_[open_blocks_[level]].mtype_;
    else return MK::none;
  }
  MarkdownStates give_type_last(){
    if(open_blocks_.num()==0) return MK::none;
    return blocks_[open_blocks_[end_MTS]].mtype_;
  }
  int is_open(int level){
    if(level<0) return 0;
    if(open_blocks_.num()>level) return blocks_[open_blocks_[level]].open_;
    else return 0;
  }
  int num_open(){ return open_blocks_.num(); }
  int block_quote_level(int ibox){
    int level=0;
    while(ibox!=0){
      if(blocks_[ibox].mtype_==MK::block_quote) level++;
      ibox=blocks_[ibox].parent_;
    }
    return level;
  }
  int list_item_level_prefix(MyTSchar& buffer,int ibox);
  int is_extension_active(MarkdownExtensions ext);
  
  int give_prev(int iblock);
  int give_next(int iblock);
  MKid* give_by_id(const char* id){ return idsG_.getH(id); }
  void process_reference_definition();
  int is_loose_last(int iblock);
  int entities_json_to_c(MyTSchar& buffer,MyTSchar& out,int start);
  
  int remove_block_quote_list_item_prefix(MyTSchar& buffer,int i,int end,int ibox);
  void create_append_paragraph(MyTSchar& buffer,int current_level);
  void process_markdown(MyTSchar& buffer);
  void output_paragraph(MyTSchar& buffer,MyTSchar& out,int start,int end,
    int ibox,int output_paraOpts=0);
  void output_paragraph(MyTSchar& buffer,MyTSchar& out,int start,int end,
    int ibox,MyTSvec<MKinline,20>& inlines,int output_paraOpts);
  void output_paragraph(MyTSchar& buffer,MyTSchar& out,int ibox);
  void output_paragraph_all_spaces(MyTSchar& buffer,int start,int end,
    MyTSchar& out,int ibox,int print_endline,int num_indent_spaces_removed,
    int check_remove_start);
  void output_paragraph_no_quoted(MyTSchar& buffer,MyTSchar& out,int ibox);
  void output_url_encoded_string(MyTSchar& buffer,MyTSchar& out,
    int start,int end);
  void output_quoted_string_nobackslash(MyTSchar& buffer,MyTSchar& out,
    int start,int end);
  void output_quoted_string_code_span(MyTSchar& buffer,MyTSchar& out,
    int start,int end);
  void output_image(int iblock,MyTSchar& buffer,MyTSchar& out,MyTSchar& url,
    MyTSchar& title,MyTSchar& text,int ibox);
  void output_link(MyTSchar& out,MyTSchar& url,MyTSchar& title,
    MyTSchar& text,int ibox,int parse_text=1);
  int is_fenced_block_info_string(MyTSchar& buffer,int start,
    MyTSchar& infostring);
  void fill_table_from_file(const char* fileName,
    MyTScharList& align,MyTSchar& out);
  int is_link_name(MyTSchar& buffer,int j,int end,int is_image,
    MyTSvec<MKinline,20>& inlines,MyTSint6& code_active);
  int is_link_href(MyTSchar& buffer,int j,int end);
  int is_link_or_image(MyTSchar& buffer,int i,int end,MyTSvec<MKinline,20>& inlines,
    MyTSint6& code_active,int only_basic_link=0);
  void parse_inlines(MyTSchar& buffer,int start,int end,
    MyTSvec<MKinline,20>& inlines,int output_paraOpts);
  
//################################################################################
//    output rdinfo
//################################################################################
  
  void init_rdinfo_lineNum(MyTSchar& out);
  void update_rdinfo_lineNum(MyTSchar& buffer,MyTSchar& out,int start);
  
//################################################################################
//    output
//################################################################################
  
  void output_markdown_start(MyTSchar& buffer,MyTSchar& out);
  void output_markdown(MyTSchar& buffer,MyTSchar& out,int ibox);
  
  static void check_init_ip();
  static void check_init_ip_gid_group_conds();
  
  protected:
  void setup_entities_json_to_c();
  void create_gid_file(const char* geoFile,const char* batch);
  
  public:
  MarkdownOutputType otype_;
  MyTSvec<MKblocks,100> blocks_;
  MyTSvecH<MKlink,10> links_;
  MyTSvecH<MyTSchar,6> metadata_;
  MyTSvecH<MKid,6> idsG_;
  MyTSint6 open_blocks_;
  IntVector2D SE_line_,SE_lineNoBlank_,blanks_line_;
  MyhashvecC<const char> entities_json_to_c_; int is_setup_entities_json_to_c_;
  static Tcl_Interp* ip_;
  static int init_ggcLib_;
  int pos_;
  int lineNum_,lineNum_pos_;
  MyTSchar* buffer_;
  MyhashvecL active_extensions_;
  MyTSint6 heading_numbers_; int heading_numbersS_;
  int image_numbers_,table_numbers_,formula_numbers_;
};

//################################################################################
//    svgml
//################################################################################

typedef enum class OTS {
  unknown,
  svg,
  rdinfo,
  tabinfo,
  gid
} SvgmlOutputType;

const char* const SvgmlOutputType_g_[]={"unknown","svg","rdinfo","tabinfo","gid",NULL};

typedef enum class OP {
  unknown,
  width,
  height,
  viewBox,
  point,
  delta_point,
  width_height,
  text,
  anchor,
  horizontal_vertical,
  cclass,
  connect_class,
  connect,
  number,
  angles,
  labels,
  ariste,
  include_children,
  operation,
  from,
  name,
  values,
  over,
  reverse_y_svg,
  
  fill,
  stroke,
  padding,
  border_stroke_width,
  border_stroke,
  border_fill,
  border_radius,
  font_family,
  font_weight,
  font_style,
  font_size,
  marker_start,marker_mid,marker_end
} SvgmlProperties;

inline int is_point_stype(SvgmlProperties p){
  return p==OP::point || p==OP::delta_point || p==OP::width_height;
}

const char* const SvgmlProperties_g_[]={"","width","height","viewBox","point","delta-point",
    "width-height","text","anchor","horizontal-vertical","class","connect-class",
    "connect","number","angles","labels","ariste","include_children","operation","from",
    "name","values","over","reverse-y-svg",
    "fill","stroke","padding",
    "border-stroke-width","border-stroke","border-fill","border-radius",
    "font-family","font-weight","font-style","font-size",
    "marker-start","marker-mid","marker-end",NULL};

typedef enum class OC {
  svgml,
  svgml_alt,
  cclass,
  region,
  line,
  rect,
  circle,
  text,
  label,
  dimension,
  image,
  cube,
  copy,
  volume,
  condition,
  problemdata
} SvgmlCommands;

const char* const SvgmlCommands_g_[]={"svgml","svgml_alt","class","region","line",
    "rect","circle","text","label","dimension","image","cube","copy","volume",
    "condition","problemdata",NULL};

typedef enum class TP {
  none,
  width_height,
  p,
  dp,
  L,
  l,
  h,
  H,
  v,
  V,
  i,
  a,
  A,
  AA,
  m,
  M,
  C,
  CC,
  c,
  cc,
  q,
  Q,
  z,
  Z,
} SvgmlPoints;

const char* const SvgmlPoints_g_[]={"none","width_height","","","L","l","h","H","v","V",
    "i","a","A","AA","m","M","C","CC","c","cc","q","Q","z","Z",NULL};

inline int is_arc(SvgmlPoints s){ return s==TP::a || s==TP::A; }
inline int is_zZ(SvgmlPoints s){ return s==TP::z || s==TP::Z; }
inline int is_qQ(SvgmlPoints s){ return s==TP::q || s==TP::Q; }
inline int is_qc(SvgmlPoints s){ return s==TP::q || s==TP::Q ||
    s==TP::c || s==TP::C || s==TP::CC || s==TP::cc; }
inline int is_cc(SvgmlPoints s){ return s==TP::CC || s==TP::cc; }
inline int is_cubic(SvgmlPoints s){ return s==TP::c || s==TP::C || s==TP::CC || s==TP::cc; }
inline int is_absolute(SvgmlPoints s){ return s==TP::p || s==TP::L || s==TP::H || s==TP::V || 
    s==TP::A || s==TP::AA || s==TP::M || s==TP::C || s==TP::CC || s==TP::Q; }
inline int is_pointBasic(SvgmlPoints s){ return s==TP::p || s==TP::M || s==TP::L || 
    s==TP::H || s==TP::V; }
inline int is_point(SvgmlPoints s){ return s==TP::p || s==TP::dp || s==TP::M || s==TP::m ||
    s==TP::L || s==TP::l || s==TP::H  || s==TP::h || s==TP::V || s==TP::v ||
    s==TP::i || s==TP::A || s==TP::a || s==TP::AA; }
inline int is_HhVv(SvgmlPoints s){ return s==TP::H  || s==TP::h || s==TP::V || s==TP::v; }
inline int is_Hh(SvgmlPoints s){ return s==TP::H || s==TP::h; }
inline int is_Vv(SvgmlPoints s){ return s==TP::V || s==TP::v; }
SvgmlPoints to_absolute(SvgmlPoints s);

typedef enum class TN {
  none,
  tangent,
  tangent_alt,
  normal
} SvgmlTangentNormal;

const char* const SvgmlTangentNormal_g_[]={"none","tangent","tangent_alt","normal",NULL};

typedef enum class TPC {
  none,vertex,ariste,face,segment,segment_inverse,all
} SvgmlPointsConnections;

const char* const SvgmlPointsConnections_g_[]={"none","vertex","ariste","face",
    "segment","segment_inverse","all",NULL};

inline int is_any_segment(SvgmlPointsConnections s){
  return s==TPC::segment || s==TPC::segment_inverse;
}

inline int is_vertex_segment(SvgmlPointsConnections s){
  return s==TPC::vertex || s==TPC::segment || s==TPC::segment_inverse;
}

typedef enum class FW {
  normal,
  bold,
} FT_FontWeight;
  
const char* const FT_FontWeight_g_[]={"normal","bold",NULL};
  
typedef enum class FS {
  normal,
  italic,
  oblique,
} FT_FontStyle;
  
const char* const FT_FontStyle_g_[]={"normal","italic","oblique",NULL};

class Svgml;
class SvgmlEntity;

class SvgmlPoint
{
  public:
  SvgmlPoint():ptype_(TP::none),connectionP_(TPC::none),point_num_(0){}
  void set_connection(SvgmlPointsConnections connectionP,int connectionN,
    const char* connection_entity){ connectionP_=connectionP;
    connectionN_=connectionN; connection_entity_.setV(connection_entity); }
  void output_gid(MyTSchar& out,Svgml& svgml,SvgmlEntity& entity);
  
  SvgmlPoints ptype_;
  glm::dvec3 point_,pointG_; // point is relative or absolute; pointG is always absolute
  MyTSvec<double,5> parameters_;
  SvgmlPointsConnections connectionP_; int connectionN_;
  MyTSchar connection_entity_;
  int point_num_; // =0 for support points; >0 for real points
  glm::ivec2 gid_numbers_;
};

class SvgmlProperty
{
  public:
  void set(SvgmlProperties name,const char* value,size_t len){
    name_=name; value_.setV(value,len);
  }
  SvgmlProperties name_;
  MyTSchar value_;
};

class Svgml;
class Svgml_copy;

class SvgmlEntity
{
  public:
  SvgmlEntity(): is_calculated_(0),is_dependent_(0){}

  void set_id(const char* id,size_t len);
  void set(const char* id,size_t len,
    SvgmlCommands cmd,
    const char* contents,size_t clen,
    const char* line,size_t llen);
  MyTSchar& give_idTS(){ return id_; }
  const char* give_id(){ return id_.v(); }
  const char* give_id_short(){ return id_short_.v(); }
  MyTSchar* give_property(SvgmlProperties prop);
  void remove_property(SvgmlProperties prop);
  const char* give_line(){ return line_.v(); }
  // x,y where values are: -1,0,1
  glm::dvec3 give_anchor_axes();
  void remove_abbreviations(Svgml& svgml);
  
  void create(int entity_num,MyTSchar& out,Svgml& svgml,Svgml_copy* copy_info=NULL);
  void calculate_points(Svgml& svgml,Svgml_copy* copy_info=NULL);
  void copy_operation(Svgml& svgml,Svgml_copy& copy_info);
  void calc_rotation_and_size(glm::dquat& rotation_vector,double& width,double& height,double& cube_height);
  void process_cube(SvgmlPointsConnections label,MyTSchar& style,MyTSchar& out,Svgml& svgml);
  void calculate_connection_point_cube(SvgmlPointsConnections point_conexion,
    int point_conexionN,int ncoords,glm::dvec3& point);
  void calculate_connection_point(SvgmlPointsConnections connectionP,
    int point_conexionN[2],SvgmlTangentNormal tangent_normal,int ncoords,
    MyTSvec<SvgmlPoint,3>& points,Svgml& svgml);
  void transform(SvgmlPoint& point,SvgmlEntity* id_parentList[3]);
  SvgmlPoint* give_point(SvgmlPoints ptype);
  void update_contents_from_properties();
  SvgmlEntity* give_copy_real_id(Svgml& svgml);
  void output_gid(MyTSchar& out,MyTSvec<SvgmlPoint,3>& points,int styleEntity,Svgml& svgml);
  SvgmlPoint* give_point(int ipoint){ return &points_[ipoint]; }
  SvgmlPoint* give_pointPN(int point_num); // do not confuse point_num with ipoint
  void give_from_entities(Svgml& svgml,MyTSint& entities);
  
  MyTSchar id_,id_short_,id_parent_;
  SvgmlCommands cmd_;
  MyTSchar contents_,line_;
  MyTSvecL<SvgmlProperty,5> properties_;
  public:
  int is_calculated_,is_dependent_;
  glm::dvec4 bbox_;
  MyTSvec<SvgmlPoint,3> points_;
  MM<int,5> gid_start_numbers_;
};

class Svgml
{
  public:
  Svgml(SvgmlOutputType otype,MKstate* mkstate=NULL);
  void process(MyTSchar& buffer,MyTSchar& out,int start,int end);
  void process_rdinfo(MyTSchar& buffer,MyTSchar& out,int start,int end,
    int& lineNum,int& lineNum_pos);
  void process_tabinfo(MyTSchar& buffer,MyTSchar& out,int start,int end);
  
  void parse_data(MyTSchar& buffer,int start,int end,const char* parent=NULL);
  void init_rdinfo_lineNum(int lineNum,int lineNum_pos);
  void give_rdinfo_lineNum(int& lineNum,int& lineNum_pos);
  void update_rdinfo_lineNum(MyTSchar& buffer,MyTSchar& out,int start,
    int is_continuation);
  void give_write_marker_id(MyTSchar& marker,const char* stroke,MyTSchar& out);
  
  SvgmlEntity* give_entity(const char* id,const char* idREF,
    int* is_abbreviated=NULL);
  int give_entityN(const char* id,const char* idREF,
    int* is_abbreviated=NULL);
  void give_descendants(const char* id,const char* id_avoid,
    MyTSvec<SvgmlEntity*,10>& entities);
  void give_descendants(const char* id,const char* id_avoid,
    MyTSint& entities);
  MyTSchar* give_property(int entity,SvgmlProperties prop);
  void append_tspans(double x,MyTSchar& label,MyTSchar& out,const char* fontname,
    FT_FontWeight fweight,FT_FontStyle fstyle,double font_size);
  void measure_tspans(MyTSchar& label,const char* fontname,
    FT_FontWeight fweight,FT_FontStyle fstyle,double font_size,
    glm::dvec4& boxG,glm::dvec4& boxG_line1);
  double evaluate_expression(const char* v,const char* line);
  // font_family, font_size must have default values
  // fill,stroke can be color,none or NULL
  // They will return updated and style might be updated
  void check_add_font_and_size(int styleEntity,MyTSchar& font_family,
    FT_FontWeight& fweight,FT_FontStyle& fstyle,double& font_size,
    const char* fill,const char* stroke,MyTSchar& style);
  int gid_common_line(int gid_point1,int gid_point2);
  int gid_common_surface(int gid_line1,int gid_line2);
  
  protected:
  MyTSchar version_;
  double width_,height_;
  int lineNum_,lineNum_pos_;
  public:
  SvgmlOutputType otype_;
  MyTSvecH<SvgmlEntity,100> entities_;
  MytextDict variables_;
  MM<int,5> gid_numbers_;
  MyTSchar gid_fileName_;
  MyTSvecL<MyTSint6,3> gid_higher_entities_[3];
  MKstate* mkstate_;
  MytextDict markers_ids_; int markers_pos_;
  static Mytextlongtable* propNames_;
  static Mytextlongtable* cmdNames_;
};

typedef enum class CO {
  translation,
  symmetry
} Svgml_copy_OPs;

const char* const Svgml_copy_OPs_g_[]={"translation","symmetry",NULL};

class Svgml_point_delta
{
  public:
  glm::dvec3 point_,delta_;
};

class Svgml_copy_OP
{
  public:
  Svgml_copy_OP(): operation_(CO::translation){}
  
  Svgml_copy_OPs operation_;
  MyTSchar operation_formula_;
  glm::dvec3 delta_;
  MyTSvec<Svgml_point_delta,10> deltaList_;
};

class Svgml_copy
{
  public:
  Svgml_copy(): init_bbox_(0),styleEntity_(-1){}
  int entity_,entity_from_;
  MyTSchar style_,connect_class_,labels_,connect_;
  int init_bbox_,styleEntity_;
  MyTSvec<Svgml_copy_OP,10> operations_;
};
  
void svgml_process(SvgmlOutputType otype,MyTSchar& buffer,MyTSchar& out,
  int start,int end,int& lineNum,int& lineNum_pos,const char* gid_fileName=NULL,
  MKstate* mkstate=NULL);

//################################################################################
//    sync_todotxt_fossil
//################################################################################

typedef enum class SP {
  none,
  todotxt,
  fossil
} SyncPref;

const char* const SyncPref_g_[]={"none","todotxt","fossil",NULL};

void sync_todotxt_fossil(const char* todotxtFile,const char* fossilFile,
  SyncPref prefer=SP::none);

//################################################################################
//    debug
//################################################################################

#if !defined(NDEBUG)
#define printf_debug(...) \
   fprintf(stdout,__VA_ARGS__); \
   fprintf(stdout,"\n"); fflush(stderr);
#else
  #define printf_debug(format,...) ((void)0)
#endif

#define printf_debug_OFF(format,...) ((void)0)
  
#endif // MARKDOWN_H










