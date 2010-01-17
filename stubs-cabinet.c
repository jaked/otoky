#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/signals.h>

#include <tcadb.h>

static value tclist_to_list(TCLIST *list) {
  return Val_int(0); /* XXX */
}

#define int_option(v) ((v == Val_int(0)) ? -1 : Int_val(Field(v, 0)))

typedef bool (*close_fn)(void *);

static void finalize_handle(value v)
{
  if (Field(v, 1)) {
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
const void *otoky_tclist_val(TCLIST *tclist, value vindex, value vsp)
{
  int sp;
  const void *val = tclistval(tclist, Int_val(vindex), &sp);
  Field(vsp, 0) = Val_int(sp);
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
  int r;
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
  int r;
  caml_enter_blocking_section();
  r = tcadbcopy(adb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r)
    adb_error(adb, "copy");
  return Val_unit;
}

CAMLprim
value otoky_adb_fwmkeys(value vadb, value vmax, value vprefix)
{
  TCADB *adb = adb_val(vadb);
  TCLIST *keys;
  value r;
  caml_enter_blocking_section();
  keys = tcadbfwmkeys(adb, String_val(vprefix), caml_string_length(vprefix), int_option(vmax));
  caml_leave_blocking_section();
  r = tclist_to_list(keys);
  tclistdel(keys);
  return r;
}
