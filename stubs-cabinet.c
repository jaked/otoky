#include <string.h>
#include <stdarg.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/signals.h>

#include <tcadb.h>



#define int_option(v) ((v == Val_int(0)) ? -1 : Int_val(Field(v, 0)))
#define int32_option(v) ((v == Val_int(0)) ? (int32)-1 : Int32_val(Field(v, 0)))
#define int64_option(v) ((v == Val_int(0)) ? (int64)-1 : Int64_val(Field(v, 0)))
#define string_option(v) ((v == Val_int(0)) ? NULL : String_val(Field(v, 0)))
#define bool_option(v) ((v == Val_int(0)) ? false : Bool_val(Field(v, 0)))

static value copy_string_length(const void *s, int len)
{
  value res = caml_alloc_string(len);
  memmove(String_val(res), s, len);
  return res;
}



enum error {
  Ethread,
  Einvalid,
  Enofile,
  Enoperm,
  Emeta,
  Erhead,
  Eopen,
  Eclose,
  Etrunc,
  Esync,
  Estat,
  Eseek,
  Eread,
  Ewrite,
  Emmap,
  Elock,
  Eunlink,
  Erename,
  Emkdir,
  Ermdir,
  Ekeep,
  Enorec,
  Emisc
};

static value *error_exn = NULL;

static void raise_error_exn(int ecode, const char *fn_name)
{
  int con = Emisc;

  CAMLlocal3(vfn_name, verr_msg, vexn);

  if (!error_exn) {
    error_exn = caml_named_value("Tokyo_cabinet.Error");
    if (!error_exn)
      caml_invalid_argument("Exception Tokyo_cabinet.Error not initialized");
  }

  switch (ecode) {
  case TCETHREAD:  con = Ethread;  break;
  case TCEINVALID: con = Einvalid; break;
  case TCENOFILE:  con = Enofile;  break;
  case TCENOPERM:  con = Enoperm;  break;
  case TCEMETA:    con = Emeta;    break;
  case TCERHEAD:   con = Erhead;   break;
  case TCEOPEN:    con = Eopen;    break;
  case TCECLOSE:   con = Eclose;   break;
  case TCETRUNC:   con = Etrunc;   break;
  case TCESYNC:    con = Esync;    break;
  case TCESTAT:    con = Estat;    break;
  case TCESEEK:    con = Eseek;    break;
  case TCEREAD:    con = Eread;    break;
  case TCEWRITE:   con = Ewrite;   break;
  case TCEMMAP:    con = Emmap;    break;
  case TCELOCK:    con = Elock;    break;
  case TCEUNLINK:  con = Eunlink;  break;
  case TCERENAME:  con = Erename;  break;
  case TCEMKDIR:   con = Emkdir;   break;
  case TCERMDIR:   con = Ermdir;   break;
  case TCEKEEP:    con = Ekeep;    break;
  case TCENOREC:   con = Enorec;   break;
  }

  vfn_name = caml_copy_string(fn_name);
  verr_msg = caml_copy_string(tcerrmsg(ecode));

  vexn = caml_alloc_small(4, 0);
  Field(vexn, 0) = *error_exn;
  Field(vexn, 1) = Val_int(con);
  Field(vexn, 2) = vfn_name;
  Field(vexn, 3) = verr_msg;
  caml_raise(vexn);
}

static value make_cstr(const void *string, int len)
{
  value vpair = caml_alloc_tuple(2);
  Field(vpair, 0) = (value)string;
  Field(vpair, 1) = Val_int(len);
  return vpair;
}

CAMLprim
value otoky_cstr_del(value vcstr)
{
  tcfree((void *)Field(vcstr, 0));
  return Val_unit;
}

enum omode {
  Oreader, Owriter, Ocreat, Otrunc, Onolck, Olcknb, Otsync
};

static int omode_int_of_list(value v)
{
  /* NB: the {H,B,T,F}DBO* enums are all the same */
  if (v == Val_int(0))
    return HDBOREADER;
  else {
    int mode = 0;
    for (v = Field(v, 0); v != Val_int(0); v = Field(v, 1)) {
      switch (Int_val(Field(v, 0))) {
      case Oreader: mode |= HDBOREADER; break;
      case Owriter: mode |= HDBOWRITER; break;
      case Ocreat:  mode |= HDBOCREAT;  break;
      case Otrunc:  mode |= HDBOTRUNC;  break;
      case Onolck:  mode |= HDBONOLCK;  break;
      case Olcknb:  mode |= HDBOLCKNB;  break;
      case Otsync:  mode |= HDBOTSYNC;  break;
      default: break;
      }
    }
    return mode;
  }
}

enum opt {
  Tlarge, Tdeflate, Tbzip, Tcbs
};

static int opt_int_of_list(value v)
{
  /* NB: the {H,B,T,F}DBT* enums are all the same */
  if (v == Val_int(0))
    return UINT8_MAX;
  else {
    int opt = 0;
    for (v = Field(v, 0); v != Val_int(0); v = Field(v, 1)) {
      switch (Int_val(Field(v, 0))) {
      case Tlarge:   opt |= HDBTLARGE;   break;
      case Tdeflate: opt |= HDBTDEFLATE; break;
      case Tbzip:    opt |= HDBTBZIP;    break;
      case Tcbs:     opt |= HDBTTCBS;     break;
      default: break;
      }
    }
    return opt;
  }
}



CAMLprim
TCLIST *otoky_tclist_new(value vanum, value vunit)
{
  int anum = int_option(vanum);
  TCLIST *tclist;
  if (anum == -1)
    tclist = tclistnew();
  else
    tclist = tclistnew2(anum);
  return tclist;
}

CAMLprim
value otoky_tclist_del(TCLIST *tclist)
{
  tclistdel(tclist);
  return Val_unit;
}

CAMLprim
value otoky_tclist_num(TCLIST *tclist)
{
  return Val_int(tclistnum(tclist));
}

CAMLprim
const void *otoky_tclist_val(TCLIST *tclist, value vindex, value vlen)
{
  int len;
  const void *val = tclistval(tclist, Int_val(vindex), &len);
  Field(vlen, 0) = Val_int(len);
  return val;
}

CAMLprim
value otoky_tclist_push(TCLIST *tclist, value vstring, value vlen)
{
  tclistpush(tclist, String_val(vstring), Int_val(vlen));
  return Val_unit;
}

CAMLprim
value otoky_tclist_lsearch(TCLIST *tclist, value vstring, value vlen)
{
  return Val_int(tclistlsearch(tclist, String_val(vstring), Int_val(vlen)));
}

CAMLprim
value otoky_tclist_bsearch(TCLIST *tclist, value vstring, value vlen)
{
  return Val_int(tclistbsearch(tclist, String_val(vstring), Int_val(vlen)));
}



/* XXX could do away with this struct */
typedef struct adb_wrap {
  TCADB *adb;
} adb_wrap;

#define adb_wrap_val(v) (*((adb_wrap **)(Data_custom_val(v))))

static void adb_finalize(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  caml_enter_blocking_section();
  (void)tcadbclose(adbw->adb);
  caml_leave_blocking_section();
  tcadbdel(adbw->adb);
  free(adbw);
}

static void adb_error(adb_wrap *adbw, const char *fn_name)
{
  /* huh, there is no way to get the error code with ADB */
  raise_error_exn(TCEMISC, fn_name);
}

CAMLprim
value otoky_adb_new(value unit)
{
  TCADB *adb = tcadbnew();
  adb_wrap *adbw;
  value vadb = caml_alloc_final(2, adb_finalize, 1, 100);
  adbw = caml_stat_alloc(sizeof(adb_wrap));
  adbw->adb = adb;
  adb_wrap_val(vadb) = adbw;
  return vadb;
}

CAMLprim
value otoky_adb_adddouble(value vadb, value vkey, value vlen, value vnum)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  double num;
  caml_enter_blocking_section();
  num = tcadbadddouble(adbw->adb, String_val(vkey), Int_val(vlen), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num)) adb_error(adbw, "adddouble");
  return caml_copy_double (num);
}

CAMLprim
value otoky_adb_addint(value vadb, value vkey, value vlen, value vnum)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  int num;
  caml_enter_blocking_section();
  num = tcadbaddint(adbw->adb, String_val(vkey), Int_val(vlen), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN) adb_error(adbw, "addint");
  return Val_int (num);
}

CAMLprim
value otoky_adb_close(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbclose(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "close");
  return Val_unit;
}

CAMLprim
value otoky_adb_copy(value vadb, value vpath)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbcopy(adbw->adb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "copy");
  return Val_unit;
}

CAMLprim
TCLIST *otoky_adb_fwmkeys(value vadb, value vmax, value vprefix, value vlen)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcadbfwmkeys(adbw->adb, String_val(vprefix), Int_val(vlen), int_option(vmax));
  caml_leave_blocking_section();
  if (!tclist) adb_error(adbw, "fwmkeys");
  return tclist;
}

CAMLprim
value otoky_adb_get(value vadb, value vkey, value vlen)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  void *val;
  int len;
  caml_enter_blocking_section();
  val = tcadbget(adbw->adb, String_val(vkey), Int_val(vlen), &len);
  caml_leave_blocking_section();
  if (!val) adb_error(adbw, "get");
  return make_cstr(val, len);
}

CAMLprim
value otoky_adb_iterinit(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbiterinit(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "iterinit");
  return Val_unit;
}

CAMLprim
value otoky_adb_iternext(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  void *key;
  int len;
  caml_enter_blocking_section();
  key = tcadbiternext(adbw->adb, &len);
  caml_leave_blocking_section();
  if (!key) adb_error(adbw, "iternext");
  return make_cstr(key, len);
}

CAMLprim
TCLIST *otoky_adb_misc(value vadb, value vname, TCLIST *args)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  TCLIST *r;
  caml_enter_blocking_section();
  r = tcadbmisc(adbw->adb, String_val(vname), args);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "misc");
  return r;
}

CAMLprim
value otoky_adb_open(value vadb, value vname)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbopen(adbw->adb, String_val(vname));
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "open");
  return Val_unit;
}

CAMLprim
value otoky_adb_optimize(value vadb, value vparams, value vunit)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadboptimize(adbw->adb, string_option(vparams));
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "optimize");
  return Val_unit;
}

CAMLprim
value otoky_adb_out(value vadb, value vkey, value vlen)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbout(adbw->adb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "out");
  return Val_unit;
}

CAMLprim
value otoky_adb_path(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  const char* path;
  caml_enter_blocking_section();
  path = tcadbpath(adbw->adb);
  caml_leave_blocking_section();
  if (!path) adb_error(adbw, "path");
  return caml_copy_string(path);
}

CAMLprim
value otoky_adb_put(value vadb, value vkey, value vkeylen, value vval, value vvallen)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbput(adbw->adb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "put");
  return Val_unit;
}

CAMLprim
value otoky_adb_putcat(value vadb, value vkey, value vkeylen, value vval, value vvallen)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbputcat(adbw->adb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "putcat");
  return Val_unit;
}

CAMLprim
value otoky_adb_putkeep(value vadb, value vkey, value vkeylen, value vval, value vvallen)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbputkeep(adbw->adb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "putkeep");
  return Val_unit;
}

CAMLprim
value otoky_adb_rnum(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcadbrnum(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "rnum");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_adb_size(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcadbsize(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "size");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_adb_sync(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbsync(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "sync");
  return Val_unit;
}

CAMLprim
value otoky_adb_tranabort(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtranabort(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "tranabort");
  return Val_unit;
}

CAMLprim
value otoky_adb_tranbegin(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtranbegin(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "tranbegin");
  return Val_unit;
}

CAMLprim
value otoky_adb_trancommit(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtrancommit(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "trancommit");
  return Val_unit;
}

CAMLprim
value otoky_adb_vanish(value vadb)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbvanish(adbw->adb);
  caml_leave_blocking_section();
  if (!r) adb_error(adbw, "vanish");
  return Val_unit;
}

CAMLprim
value otoky_adb_vsiz(value vadb, value vkey, value vkeylen)
{
  adb_wrap *adbw = adb_wrap_val(vadb);
  int r;
  caml_enter_blocking_section();
  r = tcadbvsiz(adbw->adb, String_val(vkey), Int_val(vkeylen));
  caml_leave_blocking_section();
  if (r == -1) adb_error(adbw, "vsiz");
  return Val_int(r);
}



typedef struct bdb_wrap {
  TCBDB *bdb;
  int ref_count;
  value cmpfunc;
} bdb_wrap;

#define bdb_wrap_val(v) (*((bdb_wrap **)(Data_custom_val(v))))

static void bdb_clear_cmpfunc(bdb_wrap *bdbw)
{
  if (bdbw->cmpfunc != Val_unit) {
    caml_remove_global_root(&bdbw->cmpfunc);
    bdbw->cmpfunc = Val_unit;
  }
}

static void bdb_set_cmpfunc(bdb_wrap *bdbw, value vcmpfunc)
{
  bdb_clear_cmpfunc(bdbw);
  bdbw->cmpfunc = vcmpfunc;
  caml_register_global_root(&bdbw->cmpfunc);
}

static void bdb_decr_ref_count(bdb_wrap *bdbw)
{
  if (--bdbw->ref_count == 0) {
    caml_enter_blocking_section();
    (void)tcbdbclose(bdbw->bdb);
    caml_leave_blocking_section();
    bdb_clear_cmpfunc(bdbw);
    tcbdbdel(bdbw->bdb);
    free(bdbw);
  }
}

static void bdb_finalize(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bdb_decr_ref_count(bdbw);
}

static void bdb_error(bdb_wrap *bdbw, const char *fn_name)
{
  raise_error_exn(tcbdbecode(bdbw->bdb), fn_name);
}

CAMLprim
value otoky_bdb_new(value unit)
{
  TCBDB *bdb = tcbdbnew();
  bdb_wrap *bdbw;
  value vbdb = caml_alloc_final(2, bdb_finalize, 1, 100);
  tcbdbsetmutex(bdb); /* XXX does this affect performance for single-threaded code? */
  bdbw = caml_stat_alloc(sizeof(bdb_wrap));
  bdbw->bdb = bdb;
  bdbw->ref_count = 1;
  bdbw->cmpfunc = Val_unit;
  bdb_wrap_val(vbdb) = bdbw;
  return vbdb;
}

CAMLprim
value otoky_bdb_adddouble(value vbdb, value vkey, value vlen, value vnum)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  double num;
  caml_enter_blocking_section();
  num = tcbdbadddouble(bdbw->bdb, String_val(vkey), Int_val(vlen), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num)) bdb_error(bdbw, "adddouble");
  return caml_copy_double(num);
}

CAMLprim
value otoky_bdb_addint(value vbdb, value vkey, value vlen, value vnum)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  int num;
  caml_enter_blocking_section();
  num = tcbdbaddint(bdbw->bdb, String_val(vkey), Int_val(vlen), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN) bdb_error(bdbw, "addint");
  return Val_int (num);
}

CAMLprim
value otoky_bdb_close(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbclose(bdbw->bdb);
  caml_leave_blocking_section();
  bdb_clear_cmpfunc(bdbw);
  if (!r) bdb_error(bdbw, "close");
  return Val_unit;
}

CAMLprim
value otoky_bdb_copy(value vbdb, value vpath)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcopy(bdbw->bdb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "copy");
  return Val_unit;
}

CAMLprim
value otoky_bdb_fsiz(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcbdbfsiz(bdbw->bdb);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "fsiz");
  return caml_copy_int64(r);
}

CAMLprim
TCLIST *otoky_bdb_fwmkeys(value vbdb, value vmax, value vprefix, value vlen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcbdbfwmkeys(bdbw->bdb, String_val(vprefix), Int_val(vlen), int_option(vmax));
  caml_leave_blocking_section();
  if (!tclist) bdb_error(bdbw, "fwmkeys");
  return tclist;
}

CAMLprim
value otoky_bdb_get(value vbdb, value vkey, value vlen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  void *val;
  int len;
  caml_enter_blocking_section();
  val = tcbdbget(bdbw->bdb, String_val(vkey), Int_val(vlen), &len);
  caml_leave_blocking_section();
  if (!val) bdb_error(bdbw, "get");
  return make_cstr(val, len);
}

CAMLprim
TCLIST *otoky_bdb_getlist(value vbdb, value vkey, value vlen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcbdbget4(bdbw->bdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (!tclist) bdb_error(bdbw, "getlist");
  return tclist;
}

CAMLprim
value otoky_bdb_open(value vbdb, value vmode, value vname)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbopen(bdbw->bdb, String_val(vname), omode_int_of_list(vmode));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "open");
  return Val_unit;
}

CAMLprim
value otoky_bdb_optimize(value vbdb, value vlmemb, value vnmemb, value vbnum, value vapow, value vfpow, value vopts, value vunit)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdboptimize(bdbw->bdb,
                    int32_option(vlmemb), int32_option(vnmemb), int64_option(vbnum),
                    int_option(vapow), int_option(vfpow), opt_int_of_list(vopts));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "optimize");
  return Val_unit;
}

CAMLprim
value otoky_bdb_optimize_bc(value *argv, int argn)
{
  return otoky_bdb_optimize(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
}

CAMLprim
value otoky_bdb_out(value vbdb, value vkey, value vlen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbout(bdbw->bdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "out");
  return Val_unit;
}

CAMLprim
value otoky_bdb_outlist(value vbdb, value vkey, value vlen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbout3(bdbw->bdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "outlist");
  return Val_unit;
}

CAMLprim
value otoky_bdb_path(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  const char* path;
  caml_enter_blocking_section();
  path = tcbdbpath(bdbw->bdb);
  caml_leave_blocking_section();
  if (!path) bdb_error(bdbw, "path");
  return caml_copy_string(path);
}

CAMLprim
value otoky_bdb_put(value vbdb, value vkey, value vkeylen, value vval, value vvallen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbput(bdbw->bdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "put");
  return Val_unit;
}

CAMLprim
value otoky_bdb_putcat(value vbdb, value vkey, value vkeylen, value vval, value vvallen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbputcat(bdbw->bdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "putcat");
  return Val_unit;
}

CAMLprim
value otoky_bdb_putdup(value vbdb, value vkey, value vkeylen, value vval, value vvallen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbputdup(bdbw->bdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "putdup");
  return Val_unit;
}

CAMLprim
value otoky_bdb_putkeep(value vbdb, value vkey, value vkeylen, value vval, value vvallen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbputkeep(bdbw->bdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "putkeep");
  return Val_unit;
}

CAMLprim
value otoky_bdb_putlist(value vbdb, value vkey, value vlen, TCLIST *tclist)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbputdup3(bdbw->bdb, String_val(vkey), Int_val(vlen), tclist);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "putlist");
  return Val_unit;
}

CAMLprim
TCLIST *otoky_bdb_range(value vbdb, value vbkey, value vblen, value vbinc, value vekey, value velen, value veinc, value vmax, value vunit)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcbdbrange(bdbw->bdb,
                      string_option(vbkey), Int_val(vblen), bool_option(vbinc),
                      string_option(vekey), Int_val(velen), bool_option(veinc),
                      int_option(vmax));
  caml_leave_blocking_section();
  if (!tclist) bdb_error(bdbw, "range");
  return tclist;
}

CAMLprim
TCLIST *otoky_bdb_range_bc(value *argv, int argn)
{
  return otoky_bdb_range(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8]);
}

CAMLprim
value otoky_bdb_rnum(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcbdbrnum(bdbw->bdb);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "rnum");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_bdb_setcache(value vbdb, value vlcnum, value vncnum, value vunit)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbsetcache(bdbw->bdb, int32_option(vlcnum), int32_option(vncnum));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "setcache");
  return Val_unit;
}

enum cmpfunc { Cmp_lexical, Cmp_decimal, Cmp_int32, Cmp_int64 };
enum cmpfunc_block { Cmp_custom, Cmp_custom_cstr };

static int cmp_custom(const char *aptr, int asiz, const char *bptr, int bsiz, bdb_wrap *bdbw) {
  value a, b, vr;
  int r;

  caml_leave_blocking_section();
  a = copy_string_length(aptr, asiz);
  Begin_roots1(a);
  b = copy_string_length(bptr, bsiz);
  End_roots();
  vr = caml_callback2_exn(bdbw->cmpfunc, a, b);
  if (Is_exception_result(vr))
    r = 0;
  else
    r = Int_val(vr);
  caml_enter_blocking_section();
  return r;
}

static int cmp_custom_cstr(const char *aptr, int asiz, const char *bptr, int bsiz, bdb_wrap *bdbw) {
  value vargs[] = { (value)aptr, Val_int(asiz), (value)bptr, Val_int(bsiz) };
  value vr;
  int r;

  caml_leave_blocking_section();
  vr = caml_callbackN_exn(bdbw->cmpfunc, 4, vargs);
  if (Is_exception_result(vr))
    r = 0;
  else
    r = Int_val(vr);
  caml_enter_blocking_section();
  return r;
}

CAMLprim
value otoky_bdb_setcmpfunc(value vbdb, value vcmpfunc)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  TCCMP cmp = NULL;

  if (Is_long(vcmpfunc)) {
    switch (Int_val(vcmpfunc)) {
    case Cmp_lexical: cmp = tccmplexical; break;
    case Cmp_decimal: cmp = tccmpdecimal; break;
    case Cmp_int32:   cmp = tccmpint32;   break;
    case Cmp_int64:   cmp = tccmpint64;   break;
    }
    bdb_clear_cmpfunc(bdbw);
  }
  else {
    switch (Tag_val(vcmpfunc)) {
    case Cmp_custom:      cmp = (TCCMP)cmp_custom;      break;
    case Cmp_custom_cstr: cmp = (TCCMP)cmp_custom_cstr; break;
    }
    bdb_set_cmpfunc(bdbw, Field(vcmpfunc, 0));
  }

  caml_enter_blocking_section();
  r = tcbdbsetcmpfunc(bdbw->bdb, cmp, (void *)bdbw);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "setcmpfunc");
  return Val_unit;
}

CAMLprim
value otoky_bdb_setdfunit(value vbdb, value vdfunit)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbsetdfunit(bdbw->bdb, Int32_val(vdfunit));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "setdfunit");
  return Val_unit;
}

CAMLprim
value otoky_bdb_setxmsiz(value vbdb, value vxmsiz)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbsetxmsiz(bdbw->bdb, Int64_val(vxmsiz));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "setxmsiz");
  return Val_unit;
}

CAMLprim
value otoky_bdb_sync(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbsync(bdbw->bdb);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "sync");
  return Val_unit;
}

CAMLprim
value otoky_bdb_tranabort(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbtranabort(bdbw->bdb);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "tranabort");
  return Val_unit;
}

CAMLprim
value otoky_bdb_tranbegin(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbtranbegin(bdbw->bdb);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "tranbegin");
  return Val_unit;
}

CAMLprim
value otoky_bdb_trancommit(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbtrancommit(bdbw->bdb);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "trancommit");
  return Val_unit;
}

CAMLprim
value otoky_bdb_tune(value vbdb, value vlmemb, value vnmemb, value vbnum, value vapow, value vfpow, value vopts, value vunit)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbtune(bdbw->bdb,
                int32_option(vlmemb), int32_option(vnmemb), int64_option(vbnum),
                int_option(vapow), int_option(vfpow), opt_int_of_list(vopts));
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "tune");
  return Val_unit;
}

CAMLprim
value otoky_bdb_tune_bc(value *argv, int argn)
{
  return otoky_bdb_tune(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
}

CAMLprim
value otoky_bdb_vanish(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbvanish(bdbw->bdb);
  caml_leave_blocking_section();
  if (!r) bdb_error(bdbw, "vanish");
  return Val_unit;
}

CAMLprim
value otoky_bdb_vnum(value vbdb, value vkey, value vlen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  int r;
  caml_enter_blocking_section();
  r = tcbdbvnum(bdbw->bdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (r == -1) bdb_error(bdbw, "vnum");
  return Val_int(r);
}

CAMLprim
value otoky_bdb_vsiz(value vbdb, value vkey, value vlen)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  int r;
  caml_enter_blocking_section();
  r = tcbdbvsiz(bdbw->bdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (r == -1) bdb_error(bdbw, "vsiz");
  return Val_int(r);
}



typedef struct bdbcur_wrap {
  BDBCUR *bdbcur;
  bdb_wrap *bdbw;
} bdbcur_wrap;

#define bdbcur_wrap_val(v) (*((bdbcur_wrap **)(Data_custom_val(v))))

static void bdbcur_finalize(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bdb_decr_ref_count(bdbcurw->bdbw);
  tcbdbcurdel(bdbcurw->bdbcur);
  free(bdbcurw);
}

static void bdbcur_error(bdbcur_wrap *bdbcurw, const char *fn_name)
{
  /* XXX indicate errror is from BDBCUR module */
  bdb_error(bdbcurw->bdbw, fn_name);
}

CAMLprim
value otoky_bdbcur_new(value vbdb)
{
  bdb_wrap *bdbw = bdb_wrap_val(vbdb);
  value vbdbcur;
  bdbcur_wrap *bdbcurw;
  vbdbcur = caml_alloc_final(2, bdbcur_finalize, 1, 100);
  bdbcurw = caml_stat_alloc(sizeof(bdbcur_wrap));
  bdbcurw->bdbcur = tcbdbcurnew(bdbw->bdb);
  bdbcurw->bdbw = bdbw;
  bdbw->ref_count++;
  bdbcur_wrap_val(vbdbcur) = bdbcurw;
  return vbdbcur;
}

CAMLprim
value otoky_bdbcur_first(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcurfirst(bdbcurw->bdbcur);
  caml_leave_blocking_section ();
  if (!r) bdbcur_error(bdbcurw, "first");
  return Val_unit;
}

CAMLprim
value otoky_bdbcur_jump(value vbdbcur, value vkey, value vlen)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcurjump(bdbcurw->bdbcur, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) bdbcur_error(bdbcurw, "jump");
  return Val_unit;
}

CAMLprim
value otoky_bdbcur_key(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  int len;
  const void *key;
  caml_enter_blocking_section();
  key = tcbdbcurkey(bdbcurw->bdbcur, &len);
  caml_leave_blocking_section();
  if (!key) bdbcur_error(bdbcurw, "key");
  return make_cstr(key, len);
}

CAMLprim
value otoky_bdbcur_last(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcurlast(bdbcurw->bdbcur);
  caml_leave_blocking_section ();
  if (!r) bdbcur_error(bdbcurw, "last");
  return Val_unit;
}

CAMLprim
value otoky_bdbcur_next(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcurnext(bdbcurw->bdbcur);
  caml_leave_blocking_section ();
  if (!r) bdbcur_error(bdbcurw, "next");
  return Val_unit;
}

CAMLprim
value otoky_bdbcur_out(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcurout(bdbcurw->bdbcur);
  caml_leave_blocking_section ();
  if (!r) bdbcur_error(bdbcurw, "out");
  return Val_unit;
}

CAMLprim
value otoky_bdbcur_prev(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcurprev(bdbcurw->bdbcur);
  caml_leave_blocking_section ();
  if (!r) bdbcur_error(bdbcurw, "prev");
  return Val_unit;
}

enum cpmode {
  Cp_current,
  Cp_before,
  Cp_after
};

CAMLprim
value otoky_bdbcur_put(value vbdbcur, value vcpmode, value vval, value vlen)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  bool r;
  int cpmode = BDBCPCURRENT;
  if (vcpmode != Val_int(0)) {
    switch (Int_val(Field(vcpmode, 0))) {
    case Cp_current: cpmode = BDBCPCURRENT; break;
    case Cp_before:  cpmode = BDBCPBEFORE;  break;
    case Cp_after:   cpmode = BDBCPAFTER;   break;
    }
  }
  caml_enter_blocking_section();
  r = tcbdbcurput(bdbcurw->bdbcur, String_val(vval), Int_val(vlen), cpmode);
  caml_leave_blocking_section ();
  if (!r) bdbcur_error(bdbcurw, "put");
  return Val_unit;
}

CAMLprim
value otoky_bdbcur_val(value vbdbcur)
{
  bdbcur_wrap *bdbcurw = bdbcur_wrap_val(vbdbcur);
  int len;
  const void *val;
  caml_enter_blocking_section();
  val = tcbdbcurval(bdbcurw->bdbcur, &len);
  caml_leave_blocking_section();
  if (!val) bdbcur_error(bdbcurw, "val");
  return make_cstr(val, len);
}



typedef struct fdb_wrap {
  TCFDB *fdb;
} fdb_wrap;

#define fdb_wrap_val(v) (*((fdb_wrap **)(Data_custom_val(v))))

static void fdb_finalize(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  caml_enter_blocking_section();
  (void)tcfdbclose(fdbw->fdb);
  caml_leave_blocking_section();
  tcfdbdel(fdbw->fdb);
  free(fdbw);
}

static void fdb_error(fdb_wrap *fdbw, const char *fn_name)
{
  raise_error_exn(tcfdbecode(fdbw->fdb), fn_name);
}

CAMLprim
value otoky_fdb_new(value unit)
{
  TCFDB *fdb = tcfdbnew();
  fdb_wrap *fdbw;
  value vfdb = caml_alloc_final(2, fdb_finalize, 1, 100);
  tcfdbsetmutex(fdb); /* XXX does this affect performance for single-threaded code? */
  fdbw = caml_stat_alloc(sizeof(fdb_wrap));
  fdbw->fdb = fdb;
  fdb_wrap_val(vfdb) = fdbw;
  return vfdb;
}

CAMLprim
value otoky_fdb_adddouble(value vfdb, value vkey, value vnum)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  double num;
  caml_enter_blocking_section();
  num = tcfdbadddouble(fdbw->fdb, Int64_val(vkey), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num)) fdb_error(fdbw, "adddouble");
  return caml_copy_double(num);
}

CAMLprim
value otoky_fdb_addint(value vfdb, value vkey, value vnum)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  int num;
  caml_enter_blocking_section();
  num = tcfdbaddint(fdbw->fdb, Int64_val(vkey), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN) fdb_error(fdbw, "addint");
  return Val_int (num);
}

CAMLprim
value otoky_fdb_close(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbclose(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "close");
  return Val_unit;
}

CAMLprim
value otoky_fdb_copy(value vfdb, value vpath)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbcopy(fdbw->fdb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "copy");
  return Val_unit;
}

CAMLprim
value otoky_fdb_fsiz(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcfdbfsiz(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "fsiz");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_fdb_get(value vfdb, value vkey)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  void *val;
  int len;
  caml_enter_blocking_section();
  val = tcfdbget(fdbw->fdb, Int64_val(vkey), &len);
  caml_leave_blocking_section();
  if (!val) fdb_error(fdbw, "get");
  return make_cstr(val, len);
}

CAMLprim
value otoky_fdb_iterinit(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbiterinit(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "iterinit");
  return Val_unit;
}

CAMLprim
value otoky_fdb_iternext(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  int64 key;
  caml_enter_blocking_section();
  key = tcfdbiternext(fdbw->fdb);
  caml_leave_blocking_section();
  if (!key) fdb_error(fdbw, "iternext");
  return caml_copy_int64(key);
}

CAMLprim
value otoky_fdb_open(value vfdb, value vmode, value vname)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbopen(fdbw->fdb, String_val(vname), omode_int_of_list(vmode));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "open");
  return Val_unit;
}

CAMLprim
value otoky_fdb_optimize(value vfdb, value vwidth, value vlimsiz, value vunit)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdboptimize(fdbw->fdb, int32_option(vwidth), int64_option(vlimsiz));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "optimize");
  return Val_unit;
}

CAMLprim
value otoky_fdb_out(value vfdb, value vkey)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbout(fdbw->fdb, Int64_val(vkey));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "out");
  return Val_unit;
}

CAMLprim
value otoky_fdb_path(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  const char* path;
  caml_enter_blocking_section();
  path = tcfdbpath(fdbw->fdb);
  caml_leave_blocking_section();
  if (!path) fdb_error(fdbw, "path");
  return caml_copy_string(path);
}

CAMLprim
value otoky_fdb_put(value vfdb, value vkey, value vval, value vlen)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbput(fdbw->fdb, Int64_val(vkey), String_val(vval), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "put");
  return Val_unit;
}

CAMLprim
value otoky_fdb_putcat(value vfdb, value vkey, value vval, value vlen)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbputcat(fdbw->fdb, Int64_val(vkey), String_val(vval), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "putcat");
  return Val_unit;
}

CAMLprim
value otoky_fdb_putkeep(value vfdb, value vkey, value vval, value vlen)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbputkeep(fdbw->fdb, Int64_val(vkey), String_val(vval), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "putkeep");
  return Val_unit;
}

CAMLprim
TCLIST *otoky_fdb_range(value vfdb, value vmax, value vinterval)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcfdbrange4(fdbw->fdb, String_val(vinterval), caml_string_length(vinterval), int_option(vmax));
  caml_leave_blocking_section();
  if (!tclist) fdb_error(fdbw, "range");
  return tclist;
}

CAMLprim
value otoky_fdb_rnum(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcfdbrnum(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "rnum");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_fdb_sync(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbsync(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "sync");
  return Val_unit;
}

CAMLprim
value otoky_fdb_tranabort(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbtranabort(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "tranabort");
  return Val_unit;
}

CAMLprim
value otoky_fdb_tranbegin(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbtranbegin(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "tranbegin");
  return Val_unit;
}

CAMLprim
value otoky_fdb_trancommit(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbtrancommit(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "trancommit");
  return Val_unit;
}

CAMLprim
value otoky_fdb_tune(value vfdb, value vwidth, value vlimsiz, value vunit)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbtune(fdbw->fdb, int32_option(vwidth), int64_option(vlimsiz));
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "tune");
  return Val_unit;
}

CAMLprim
value otoky_fdb_vanish(value vfdb)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  bool r;
  caml_enter_blocking_section();
  r = tcfdbvanish(fdbw->fdb);
  caml_leave_blocking_section();
  if (!r) fdb_error(fdbw, "vanish");
  return Val_unit;
}

CAMLprim
value otoky_fdb_vsiz(value vfdb, value vkey)
{
  fdb_wrap *fdbw = fdb_wrap_val(vfdb);
  int r;
  caml_enter_blocking_section();
  r = tcfdbvsiz(fdbw->fdb, Int64_val(vkey));
  caml_leave_blocking_section();
  if (r == -1) fdb_error(fdbw, "vsiz");
  return Val_int(r);
}



typedef struct hdb_wrap {
  TCHDB *hdb;
} hdb_wrap;

#define hdb_wrap_val(v) (*((hdb_wrap **)(Data_custom_val(v))))

static void hdb_finalize(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  caml_enter_blocking_section();
  (void)tchdbclose(hdbw->hdb);
  caml_leave_blocking_section();
  tchdbdel(hdbw->hdb);
  free(hdbw);
}

static void hdb_error(hdb_wrap *hdbw, const char *fn_name)
{
  raise_error_exn(tchdbecode(hdbw->hdb), fn_name);
}

CAMLprim
value otoky_hdb_new(value unit)
{
  TCHDB *hdb = tchdbnew();
  hdb_wrap *hdbw;
  value vhdb = caml_alloc_final(2, hdb_finalize, 1, 100);
  tchdbsetmutex(hdb); /* XXX does this affect performance for single-threaded code? */
  hdbw = caml_stat_alloc(sizeof(hdb_wrap));
  hdbw->hdb = hdb;
  hdb_wrap_val(vhdb) = hdbw;
  return vhdb;
}

CAMLprim
value otoky_hdb_adddouble(value vhdb, value vkey, value vlen, value vnum)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  double num;
  caml_enter_blocking_section();
  num = tchdbadddouble(hdbw->hdb, String_val(vkey), Int_val(vlen), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num)) hdb_error(hdbw, "adddouble");
  return caml_copy_double(num);
}

CAMLprim
value otoky_hdb_addint(value vhdb, value vkey, value vlen, value vnum)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  int num;
  caml_enter_blocking_section();
  num = tchdbaddint(hdbw->hdb, String_val(vkey), Int_val(vlen), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN) hdb_error(hdbw, "addint");
  return Val_int (num);
}

CAMLprim
value otoky_hdb_close(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbclose(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "close");
  return Val_unit;
}

CAMLprim
value otoky_hdb_copy(value vhdb, value vpath)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbcopy(hdbw->hdb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "copy");
  return Val_unit;
}

CAMLprim
value otoky_hdb_fsiz(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tchdbfsiz(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "fsiz");
  return caml_copy_int64(r);
}

CAMLprim
TCLIST *otoky_hdb_fwmkeys(value vhdb, value vmax, value vprefix, value vlen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tchdbfwmkeys(hdbw->hdb, String_val(vprefix), Int_val(vlen), int_option(vmax));
  caml_leave_blocking_section();
  if (!tclist) hdb_error(hdbw, "fwmkeys");
  return tclist;
}

CAMLprim
value otoky_hdb_get(value vhdb, value vkey, value vlen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  void *val;
  int len;
  caml_enter_blocking_section();
  val = tchdbget(hdbw->hdb, String_val(vkey), Int_val(vlen), &len);
  caml_leave_blocking_section();
  if (!val) hdb_error(hdbw, "get");
  return make_cstr(val, len);
}

CAMLprim
value otoky_hdb_iterinit(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbiterinit(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "iterinit");
  return Val_unit;
}

CAMLprim
value otoky_hdb_iternext(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  void *key;
  int len;
  caml_enter_blocking_section();
  key = tchdbiternext(hdbw->hdb, &len);
  caml_leave_blocking_section();
  if (!key) hdb_error(hdbw, "iternext");
  return make_cstr(key, len);
}

CAMLprim
value otoky_hdb_open(value vhdb, value vmode, value vname)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbopen(hdbw->hdb, String_val(vname), omode_int_of_list(vmode));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "open");
  return Val_unit;
}

CAMLprim
value otoky_hdb_optimize(value vhdb, value vbnum, value vapow, value vfpow, value vopts, value vunit)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdboptimize(hdbw->hdb,
                    int64_option(vbnum), int_option(vapow), int_option(vfpow), opt_int_of_list(vopts));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "optimize");
  return Val_unit;
}

CAMLprim
value otoky_hdb_optimize_bc(value *argv, int argn)
{
  return otoky_hdb_optimize(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim
value otoky_hdb_out(value vhdb, value vkey, value vlen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbout(hdbw->hdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "out");
  return Val_unit;
}

CAMLprim
value otoky_hdb_path(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  const char* path;
  caml_enter_blocking_section();
  path = tchdbpath(hdbw->hdb);
  caml_leave_blocking_section();
  if (!path) hdb_error(hdbw, "path");
  return caml_copy_string(path);
}

CAMLprim
value otoky_hdb_put(value vhdb, value vkey, value vkeylen, value vval, value vvallen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbput(hdbw->hdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "put");
  return Val_unit;
}

CAMLprim
value otoky_hdb_putasync(value vhdb, value vkey, value vkeylen, value vval, value vvallen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbputasync(hdbw->hdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "putasync");
  return Val_unit;
}

CAMLprim
value otoky_hdb_putcat(value vhdb, value vkey, value vkeylen, value vval, value vvallen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbputcat(hdbw->hdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "putcat");
  return Val_unit;
}

CAMLprim
value otoky_hdb_putkeep(value vhdb, value vkey, value vkeylen, value vval, value vvallen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbputkeep(hdbw->hdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "putkeep");
  return Val_unit;
}

CAMLprim
value otoky_hdb_rnum(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tchdbrnum(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "rnum");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_hdb_setcache(value vhdb, value vrcnum)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbsetcache(hdbw->hdb, Int32_val(vrcnum));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "setcache");
  return Val_unit;
}

CAMLprim
value otoky_hdb_setdfunit(value vhdb, value vdfunit)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbsetdfunit(hdbw->hdb, Int32_val(vdfunit));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "setdfunit");
  return Val_unit;
}

CAMLprim
value otoky_hdb_setxmsiz(value vhdb, value vxmsiz)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbsetxmsiz(hdbw->hdb, Int64_val(vxmsiz));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "setxmsiz");
  return Val_unit;
}

CAMLprim
value otoky_hdb_sync(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbsync(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "sync");
  return Val_unit;
}

CAMLprim
value otoky_hdb_tranabort(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbtranabort(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "tranabort");
  return Val_unit;
}

CAMLprim
value otoky_hdb_tranbegin(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbtranbegin(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "tranbegin");
  return Val_unit;
}

CAMLprim
value otoky_hdb_trancommit(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbtrancommit(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "trancommit");
  return Val_unit;
}

CAMLprim
value otoky_hdb_tune(value vhdb, value vbnum, value vapow, value vfpow, value vopts, value vunit)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbtune(hdbw->hdb,
                int64_option(vbnum), int_option(vapow), int_option(vfpow), opt_int_of_list(vopts));
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "tune");
  return Val_unit;
}

CAMLprim
value otoky_hdb_tune_bc(value *argv, int argn)
{
  return otoky_hdb_tune(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim
value otoky_hdb_vanish(value vhdb)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  bool r;
  caml_enter_blocking_section();
  r = tchdbvanish(hdbw->hdb);
  caml_leave_blocking_section();
  if (!r) hdb_error(hdbw, "vanish");
  return Val_unit;
}

CAMLprim
value otoky_hdb_vsiz(value vhdb, value vkey, value vlen)
{
  hdb_wrap *hdbw = hdb_wrap_val(vhdb);
  int r;
  caml_enter_blocking_section();
  r = tchdbvsiz(hdbw->hdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (r == -1) hdb_error(hdbw, "vsiz");
  return Val_int(r);
}
