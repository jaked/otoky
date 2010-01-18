#include <string.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/signals.h>

#include <tcadb.h>

#define int_option(v) ((v == Val_int(0)) ? -1 : Int_val(Field(v, 0)))
#define string_option(v) ((v == Val_int(0)) ? NULL : String_val(Field(v, 0)))

typedef bool (*close_fn)(void *);

static void finalize_handle(value v)
{
  if (Field(v, 1))
  {
    caml_enter_blocking_section();
    (void)((close_fn)Field(v, 1))((void *)Field(v, 0));
    Field(v, 1) = 0;
    caml_leave_blocking_section();
  }
}

static value alloc_handle(void *p, close_fn close)
{
  value v = caml_alloc_final(2, finalize_handle, 100, 1000);
  Field(v, 0) = (value)p;
  Field(v, 1) = (value)close;
  return v;
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

static void adb_error(TCADB *adb, char *fn_name)
{
  /* XXX */
}

static TCADB *adb_val(value v)
{
  /* XXX raise if closed */
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
  TCADB *adb = adb_val(vadb);
  double num;
  caml_enter_blocking_section();
  num = tcadbadddouble(adb, String_val(vkey), caml_string_length(vkey), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num))
    adb_error(adb, "adddouble");
  return caml_copy_double (num);
}

CAMLprim
value otoky_adb_addint(value vadb, value vkey, value vnum)
{
  TCADB *adb = adb_val(vadb);
  int num;
  caml_enter_blocking_section();
  num = tcadbaddint(adb, String_val(vkey), caml_string_length(vkey), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN)
    adb_error(adb, "addint");
  return caml_copy_double (num);
}

CAMLprim
value otoky_adb_close(value vadb)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbclose(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "close");
  return Val_unit;
}

CAMLprim
value otoky_adb_copy(value vadb, value vpath)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbcopy(adb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "copy");
  return Val_unit;
}

CAMLprim
TCLIST *otoky_adb_fwmkeys(value vadb, value vmax, value vprefix)
{
  TCADB *adb = adb_val(vadb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcadbfwmkeys(adb, String_val(vprefix), caml_string_length(vprefix), int_option(vmax));
  caml_leave_blocking_section();
  return tclist;
}

CAMLprim
value otoky_adb_get(value vadb, value vkey)
{
  TCADB *adb = adb_val(vadb);
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
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbiterinit(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "iterinit");
  return Val_unit;
}

CAMLprim
value otoky_adb_iternext(value vadb)
{
  TCADB *adb = adb_val(vadb);
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
  TCADB *adb = adb_val(vadb);
  TCLIST *r;
  caml_enter_blocking_section();
  r = tcadbmisc(adb, String_val(vname), args);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "misc");
  return r;
}

CAMLprim
value otoky_adb_open(value vadb, value vname)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbopen(adb, String_val(vname));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "open");
  return Val_unit;
}

CAMLprim
value otoky_adb_optimize(value vadb, value vparams, value vunit)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadboptimize(adb, string_option(vparams));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "optimize");
  return Val_unit;
}

CAMLprim
value otoky_adb_out(value vadb, value vkey)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbout(adb, String_val(vkey), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "optimize");
  return Val_unit;
}

CAMLprim
value otoky_adb_path(value vadb)
{
  TCADB *adb = adb_val(vadb);
  const char* path;
  caml_enter_blocking_section();
  path = tcadbpath(adb);
  caml_leave_blocking_section();
  if (!path)
    caml_raise_not_found();
  return caml_copy_string(path);
}

CAMLprim
value otoky_adb_put(value vadb, value vkey, value vval)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbput(adb, String_val(vkey), caml_string_length(vkey), String_val(vval), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "put");
  return Val_unit;
}

CAMLprim
value otoky_adb_putcat(value vadb, value vkey, value vval)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbputcat(adb, String_val(vkey), caml_string_length(vkey), String_val(vval), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "putcat");
  return Val_unit;
}

CAMLprim
value otoky_adb_putkeep(value vadb, value vkey, value vval)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbputkeep(adb, String_val(vkey), caml_string_length(vkey), String_val(vval), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "putkeep");
  return Val_unit;
}

CAMLprim
value otoky_adb_rnum(value vadb)
{
  TCADB *adb = adb_val(vadb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcadbrnum(adb);
  caml_leave_blocking_section();
  return caml_copy_int64(r);
}

CAMLprim
value otoky_adb_size(value vadb)
{
  TCADB *adb = adb_val(vadb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcadbsize(adb);
  caml_leave_blocking_section();
  return caml_copy_int64(r);
}

CAMLprim
value otoky_adb_sync(value vadb)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbsync(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "sync");
  return Val_unit;
}

CAMLprim
value otoky_adb_tranabort(value vadb)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtranabort(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "tranabort");
  return Val_unit;
}

CAMLprim
value otoky_adb_tranbegin(value vadb)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtranbegin(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "tranbegin");
  return Val_unit;
}

CAMLprim
value otoky_adb_trancommit(value vadb)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbtrancommit(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "trancommit");
  return Val_unit;
}

CAMLprim
value otoky_adb_vanish(value vadb)
{
  TCADB *adb = adb_val(vadb);
  bool r;
  caml_enter_blocking_section();
  r = tcadbvanish(adb);
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "vanish");
  return Val_unit;
}

CAMLprim
value otoky_adb_vsiz(value vadb, value vkey)
{
  TCADB *adb = adb_val(vadb);
  int r;
  caml_enter_blocking_section();
  r = tcadbvsiz(adb, String_val(vkey), caml_string_length(vkey));
  caml_leave_blocking_section();
  if (r == -1)
    adb_error(adb, "vsiz");
  return Val_int(r);
}

