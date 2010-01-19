#include <string.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/signals.h>

#include <tcadb.h>

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

static void raise_error_exn(int con, const char *fn_name, const char *err_msg)
{
  CAMLlocal3(vfn_name, verr_msg, vexn);

  if (!error_exn) {
    error_exn = caml_named_value("Tokyo_cabinet.Error");
    if (!error_exn)
      invalid_argument("Exception Tokyo_cabinet.Error not initialized");
  }

  vfn_name = caml_copy_string(fn_name);
  verr_msg = caml_copy_string(err_msg);
  
  vexn = caml_alloc_small(4, 0);
  Field(vexn, 0) = *error_exn;
  Field(vexn, 1) = Val_int(con);
  Field(vexn, 2) = vfn_name;
  Field(vexn, 3) = verr_msg;
  caml_raise(vexn);
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

#define int_option(v) ((v == Val_int(0)) ? -1 : Int_val(Field(v, 0)))
#define int32_option(v) ((v == Val_int(0)) ? (int32)-1 : Int32_val(Field(v, 0)))
#define int64_option(v) ((v == Val_int(0)) ? (int64)-1 : Int64_val(Field(v, 0)))
#define string_option(v) ((v == Val_int(0)) ? NULL : String_val(Field(v, 0)))

typedef bool (*close_fn)(void *);

static void finalize_handle(value v)
{
  if (Bool_val(Field(v, 2)))
  {
    caml_enter_blocking_section();
    (void)((close_fn)Field(v, 1))((void *)Field(v, 0));
    Field(v, 2) = Val_false;
    caml_leave_blocking_section();
  }
}

static value alloc_handle(void *p, close_fn close)
{
  value v = caml_alloc_final(2, finalize_handle, 100, 1000);
  Field(v, 0) = (value)p;
  Field(v, 1) = (value)close;
  Field(v, 2) = Val_false;
  return v;
}

static void set_handle_open(value v, bool open)
{
  Field(v, 2) = Val_bool(open);
}

static value copy_string_len(void *s, int len)
{
  value res = caml_alloc_string(len);
  memmove(String_val(res), s, len);
  return res;
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
value otoky_tclist_push(TCLIST *tclist, value vstring)
{
  tclistpush(tclist, String_val(vstring), caml_string_length(vstring));
  return Val_unit;
}

CAMLprim
value otoky_tclist_lsearch(TCLIST *tclist, value vstring)
{
  return Val_int(tclistlsearch(tclist, String_val(vstring), caml_string_length(vstring)));
}

CAMLprim
value otoky_tclist_bsearch(TCLIST *tclist, value vstring)
{
  return Val_int(tclistbsearch(tclist, String_val(vstring), caml_string_length(vstring)));
}



static void adb_error(TCADB *adb, const char *fn_name)
{
  /* huh, there is no way to get the error code with ADB */
  raise_error_exn(Emisc, fn_name, "");
}

static TCADB *adb_open_val(value v, const char *fn_name)
{
  
  if (!Bool_val(Field(v, 2))) {
    char buf[80];
    sprintf(buf, "%s: handle is closed", fn_name);
    caml_invalid_argument(buf);
  }
  return (TCADB *)Field(v, 0);
}

static TCADB *adb_val(value v)
{
  return (TCADB *)Field(v, 0);
}

CAMLprim
value otoky_adb_new(value unit)
{
  TCADB *adb = tcadbnew();
  return alloc_handle(adb, (close_fn)tcadbclose);
}

CAMLprim
value otoky_adb_adddouble(value vadb, value vkey, value vnum)
{
  const char *fn_name = "adddouble";
  TCADB *adb = adb_open_val(vadb, fn_name);
  double num;
  caml_enter_blocking_section();
  num = tcadbadddouble(adb, String_val(vkey), caml_string_length(vkey), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num))
    adb_error(adb, fn_name);
  return caml_copy_double (num);
}

CAMLprim
value otoky_adb_addint(value vadb, value vkey, value vnum)
{
  const char *fn_name = "addint";
  TCADB *adb = adb_open_val(vadb, fn_name);
  int num;
  caml_enter_blocking_section();
  num = tcadbaddint(adb, String_val(vkey), caml_string_length(vkey), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN)
    adb_error(adb, fn_name);
  return Val_int (num);
}

CAMLprim
value otoky_adb_close(value vadb)
{
  const char *fn_name = "close";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbclose(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  set_handle_open(vadb, false);
  return Val_unit;
}

CAMLprim
value otoky_adb_copy(value vadb, value vpath)
{
  const char *fn_name = "copy";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbcopy(adb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
TCLIST *otoky_adb_fwmkeys(value vadb, value vmax, value vprefix)
{
  const char *fn_name = "fwmkeys";
  TCADB *adb = adb_open_val(vadb, fn_name);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcadbfwmkeys(adb, String_val(vprefix), caml_string_length(vprefix), int_option(vmax));
  caml_leave_blocking_section();
  return tclist;
}

CAMLprim
value otoky_adb_get(value vadb, value vkey)
{
  const char *fn_name = "get";
  TCADB *adb = adb_open_val(vadb, fn_name);
  void *val;
  int len;
  value vval;
  caml_enter_blocking_section();
  val = tcadbget(adb, String_val(vkey), caml_string_length(vkey), &len);
  caml_leave_blocking_section();
  if (!val) caml_raise_not_found ();
  vval = copy_string_len(val, len);
  tcfree(val);
  return vval;
}

CAMLprim
value otoky_adb_iterinit(value vadb)
{
  const char *fn_name = "iterinit";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbiterinit(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_iternext(value vadb)
{
  const char *fn_name = "iternext";
  TCADB *adb = adb_open_val(vadb, fn_name);
  void *val;
  int len;
  value vval;
  caml_enter_blocking_section();
  val = tcadbiternext(adb, &len);
  caml_leave_blocking_section();
  if (!val) caml_raise_not_found ();
  vval = copy_string_len(val, len);
  tcfree(val);
  return vval;
}

CAMLprim
TCLIST *otoky_adb_misc(value vadb, value vname, TCLIST *args)
{
  const char *fn_name = "misc";
  TCADB *adb = adb_open_val(vadb, fn_name);
  TCLIST *r;
  caml_enter_blocking_section();
  r = tcadbmisc(adb, String_val(vname), args);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return r;
}

CAMLprim
value otoky_adb_open(value vadb, value vname)
{
  const char *fn_name = "open";
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbopen(adb, String_val(vname));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  set_handle_open(vadb, true);
  return Val_unit;
}

CAMLprim
value otoky_adb_optimize(value vadb, value vparams, value vunit)
{
  const char *fn_name = "optimize";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadboptimize(adb, string_option(vparams));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_out(value vadb, value vkey)
{
  const char *fn_name = "out";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbout(adb, String_val(vkey), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_path(value vadb)
{
  const char *fn_name = "path";
  TCADB *adb = adb_open_val(vadb, fn_name);
  const char* path;
  caml_enter_blocking_section();
  path = tcadbpath(adb);
  caml_leave_blocking_section();
  if (!path) /* shouldn't happen */
    caml_raise_not_found();
  return caml_copy_string(path);
}

CAMLprim
value otoky_adb_put(value vadb, value vkey, value vval)
{
  const char *fn_name = "put";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbput(adb, String_val(vkey), caml_string_length(vkey), String_val(vval), caml_string_length(vval));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_putcat(value vadb, value vkey, value vval)
{
  const char *fn_name = "putcat";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbputcat(adb, String_val(vkey), caml_string_length(vkey), String_val(vval), caml_string_length(vval));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_putkeep(value vadb, value vkey, value vval)
{
  const char *fn_name = "putkeep";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbputkeep(adb, String_val(vkey), caml_string_length(vkey), String_val(vval), caml_string_length(vval));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_rnum(value vadb)
{
  const char *fn_name = "rnum";
  TCADB *adb = adb_open_val(vadb, fn_name);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcadbrnum(adb);
  caml_leave_blocking_section();
  return caml_copy_int64(r);
}

CAMLprim
value otoky_adb_size(value vadb)
{
  const char *fn_name = "size";
  TCADB *adb = adb_open_val(vadb, fn_name);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcadbsize(adb);
  caml_leave_blocking_section();
  return caml_copy_int64(r);
}

CAMLprim
value otoky_adb_sync(value vadb)
{
  const char *fn_name = "sync";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbsync(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_tranabort(value vadb)
{
  const char *fn_name = "tranabort";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtranabort(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_tranbegin(value vadb)
{
  const char *fn_name = "tranbegin";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtranbegin(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_trancommit(value vadb)
{
  const char *fn_name = "trancommit";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtrancommit(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_vanish(value vadb)
{
  const char *fn_name = "vanish";
  TCADB *adb = adb_open_val(vadb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcadbvanish(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_adb_vsiz(value vadb, value vkey)
{
  const char *fn_name = "vsiz";
  TCADB *adb = adb_open_val(vadb, fn_name);
  int r;
  caml_enter_blocking_section();
  r = tcadbvsiz(adb, String_val(vkey), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (r == -1)
    adb_error(adb, fn_name);
  return Val_int(r);
}



static void bdb_error(TCBDB *bdb, const char *fn_name)
{
  /* XXX fix for BDB */
  raise_error_exn(Emisc, fn_name, "");
}

static TCBDB *bdb_open_val(value v, const char *fn_name)
{
  
  if (!Bool_val(Field(v, 2))) {
    char buf[80];
    sprintf(buf, "%s: handle is closed", fn_name);
    caml_invalid_argument(buf);
  }
  return (TCBDB *)Field(v, 0);
}

static TCBDB *bdb_val(value v)
{
  return (TCBDB *)Field(v, 0);
}

CAMLprim
value otoky_bdb_new(value unit)
{
  TCBDB *bdb = tcbdbnew();
  return alloc_handle(bdb, (close_fn)tcbdbclose);
}

CAMLprim
value otoky_bdb_adddouble(value vbdb, value vkey, value vnum)
{
  const char *fn_name = "adddouble";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  double num;
  caml_enter_blocking_section();
  num = tcbdbadddouble(bdb, String_val(vkey), caml_string_length(vkey), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num))
    bdb_error(bdb, fn_name);
  return caml_copy_double (num);
}

CAMLprim
value otoky_bdb_addint(value vbdb, value vkey, value vnum)
{
  const char *fn_name = "addint";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  int num;
  caml_enter_blocking_section();
  num = tcbdbaddint(bdb, String_val(vkey), caml_string_length(vkey), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN)
    bdb_error(bdb, fn_name);
  return Val_int (num);
}

CAMLprim
value otoky_bdb_close(value vbdb)
{
  const char *fn_name = "close";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbclose(bdb);
  caml_leave_blocking_section();
  if (!r)
    bdb_error(bdb, fn_name);
  set_handle_open(vbdb, false);
  return Val_unit;
}

CAMLprim
value otoky_bdb_copy(value vbdb, value vpath)
{
  const char *fn_name = "copy";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbcopy(bdb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r)
    bdb_error(bdb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_bdb_fsiz(value vbdb)
{
  const char *fn_name = "fsiz";
  TCBDB *adb = bdb_open_val(vbdb, fn_name);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcbdbfsiz(adb);
  caml_leave_blocking_section();
  return caml_copy_int64(r);
}

CAMLprim
TCLIST *otoky_bdb_fwmkeys(value vbdb, value vmax, value vprefix)
{
  const char *fn_name = "fwmkeys";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcbdbfwmkeys(bdb, String_val(vprefix), caml_string_length(vprefix), int_option(vmax));
  caml_leave_blocking_section();
  return tclist;
}

CAMLprim
value otoky_bdb_get(value vbdb, value vkey)
{
  const char *fn_name = "get";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  void *val;
  int len;
  value vval;
  caml_enter_blocking_section();
  val = tcbdbget(bdb, String_val(vkey), caml_string_length(vkey), &len);
  caml_leave_blocking_section();
  if (!val) caml_raise_not_found ();
  vval = copy_string_len(val, len);
  tcfree(val);
  return vval;
}

CAMLprim
TCLIST *otoky_bdb_getlist(value vbdb, value vkey)
{
  const char *fn_name = "getlist";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcbdbget4(bdb, String_val(vkey), caml_string_length(vkey));
  caml_leave_blocking_section();
  return tclist;
}

CAMLprim
value otoky_bdb_open(value vbdb, value vmode, value vname)
{
  const char *fn_name = "open";
  TCBDB *bdb = bdb_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbopen(bdb, String_val(vname), omode_int_of_list(vmode));
  caml_leave_blocking_section();
  if (!r)
    bdb_error(bdb, fn_name);
  set_handle_open(vbdb, true);
  return Val_unit;
}

CAMLprim
value otoky_bdb_optimize(value vbdb, value vlmemb, value vnmemb, value vbnum, value vapow, value vfpow, value vopts, value vunit)
{
  const char *fn_name = "optimize";
  TCBDB *bdb = bdb_val(vbdb);
  bool r;
  caml_enter_blocking_section();
  r = tcbdboptimize(bdb,
		    int32_option(vlmemb), int32_option(vnmemb), int64_option(vbnum),
		    int_option(vapow), int_option(vfpow), opt_int_of_list(vopts));
  caml_leave_blocking_section();
  if (!r)
    bdb_error(bdb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_bdb_optimize_bc(value *argv, int argn)
{
  return otoky_bdb_optimize(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
}

CAMLprim
value otoky_bdb_out(value vbdb, value vkey)
{
  const char *fn_name = "out";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbout(bdb, String_val(vkey), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (!r)
    bdb_error(bdb, fn_name);
  return Val_unit;
}

CAMLprim
value otoky_bdb_outlist(value vbdb, value vkey)
{
  const char *fn_name = "outlist";
  TCBDB *bdb = bdb_open_val(vbdb, fn_name);
  bool r;
  caml_enter_blocking_section();
  r = tcbdbout3(bdb, String_val(vkey), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (!r)
    bdb_error(bdb, fn_name);
  return Val_unit;
}
