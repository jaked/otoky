#include <string.h>
#include <stdarg.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/signals.h>

#include <tcrdb.h>



#define int_option(v) ((v == Val_int(0)) ? -1 : Int_val(Field(v, 0)))
#define int_option0(v) ((v == Val_int(0)) ? 0 : Int_val(Field(v, 0)))
#define int32_option(v) ((v == Val_int(0)) ? (int32)-1 : Int32_val(Field(v, 0)))
#define int64_option(v) ((v == Val_int(0)) ? (int64)-1 : Int64_val(Field(v, 0)))
#define string_option(v) ((v == Val_int(0)) ? NULL : String_val(Field(v, 0)))
#define double_option(v) ((v == Val_int(0)) ? 0 : Double_val(Field(v, 0)))
#define bool_option(v) ((v == Val_int(0)) ? false : Bool_val(Field(v, 0)))



enum error {
  Einvalid,
  Enohost,
  Erefused,
  Esend,
  Erecv,
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
    error_exn = caml_named_value("Tokyo_tyrant.Error");
    if (!error_exn)
      caml_invalid_argument("Exception Tokyo_tyrant.Error not initialized");
  }

  switch (ecode) {
  case TTEINVALID: con = Einvalid; break;
  case TTENOHOST:  con = Enohost;  break;
  case TTEREFUSED: con = Erefused;  break;
  case TTESEND:    con = Esend;    break;
  case TTERECV:    con = Erecv;    break;
  case TTEKEEP:    con = Ekeep;    break;
  case TTENOREC:   con = Enorec;   break;
  }

  vfn_name = caml_copy_string(fn_name);
  verr_msg = caml_copy_string(tcrdberrmsg(ecode));

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



typedef struct rdb_wrap {
  TCRDB *rdb;
} rdb_wrap;

#define rdb_wrap_val(v) (*((rdb_wrap **)(Data_custom_val(v))))

static void rdb_finalize(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  caml_enter_blocking_section();
  (void)tcrdbclose(rdbw->rdb);
  caml_leave_blocking_section();
  tcrdbdel(rdbw->rdb);
  free(rdbw);
}

static void rdb_error(rdb_wrap *rdbw, const char *fn_name)
{
  raise_error_exn(tcrdbecode(rdbw->rdb), fn_name);
}

CAMLprim
value otoky_rdb_new(value unit)
{
  TCRDB *rdb = tcrdbnew();
  rdb_wrap *rdbw;
  value vrdb = caml_alloc_final(2, rdb_finalize, 1, 100);
  rdbw = caml_stat_alloc(sizeof(rdb_wrap));
  rdbw->rdb = rdb;
  rdb_wrap_val(vrdb) = rdbw;
  return vrdb;
}

CAMLprim
value otoky_rdb_adddouble(value vrdb, value vkey, value vlen, value vnum)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  double num;
  caml_enter_blocking_section();
  num = tcrdbadddouble(rdbw->rdb, String_val(vkey), Int_val(vlen), Double_val(vnum));
  caml_leave_blocking_section();
  if (isnan(num)) rdb_error(rdbw, "adddouble");
  return caml_copy_double (num);
}

CAMLprim
value otoky_rdb_addint(value vrdb, value vkey, value vlen, value vnum)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  int num;
  caml_enter_blocking_section();
  num = tcrdbaddint(rdbw->rdb, String_val(vkey), Int_val(vlen), Int_val(vnum));
  caml_leave_blocking_section();
  if (num == INT_MIN) rdb_error(rdbw, "addint");
  return Val_int (num);
}

CAMLprim
value otoky_rdb_close(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbclose(rdbw->rdb);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "close");
  return Val_unit;
}

CAMLprim
value otoky_rdb_copy(value vrdb, value vpath)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbcopy(rdbw->rdb, String_val(vpath));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "copy");
  return Val_unit;
}

CAMLprim
TCLIST *otoky_rdb_fwmkeys(value vrdb, value vmax, value vprefix, value vlen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  TCLIST *tclist;
  caml_enter_blocking_section();
  tclist = tcrdbfwmkeys(rdbw->rdb, String_val(vprefix), Int_val(vlen), int_option(vmax));
  caml_leave_blocking_section();
  if (!tclist) rdb_error(rdbw, "fwmkeys");
  return tclist;
}

CAMLprim
value otoky_rdb_get(value vrdb, value vkey, value vlen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  void *val;
  int len;
  caml_enter_blocking_section();
  val = tcrdbget(rdbw->rdb, String_val(vkey), Int_val(vlen), &len);
  caml_leave_blocking_section();
  if (!val) rdb_error(rdbw, "get");
  return make_cstr(val, len);
}

CAMLprim
value otoky_rdb_iterinit(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbiterinit(rdbw->rdb);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "iterinit");
  return Val_unit;
}

CAMLprim
value otoky_rdb_iternext(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  void *key;
  int len;
  caml_enter_blocking_section();
  key = tcrdbiternext(rdbw->rdb, &len);
  caml_leave_blocking_section();
  if (!key) rdb_error(rdbw, "iternext");
  return make_cstr(key, len);
}

enum mopt { Monoulog };

static int mopts_int_of_list(value v)
{
  if (v == Val_int(0))
    return 0;
  else {
    int mopts = 0;
    for (v = Field(v, 0); v != Val_int(0); v = Field(v, 1)) {
      switch (Int_val(Field(v, 0))) {
      case Monoulog: mopts |= RDBMONOULOG; break;
      }
    }
    return mopts;
  }
}

CAMLprim
TCLIST *otoky_rdb_misc(value vrdb, value vmopts, value vname, TCLIST *args)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  TCLIST *r;
  caml_enter_blocking_section();
  r = tcrdbmisc(rdbw->rdb, String_val(vname), mopts_int_of_list(vmopts), args);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "misc");
  return r;
}

CAMLprim
value otoky_rdb_open(value vrdb, value vname, value vport)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbopen(rdbw->rdb, String_val(vname), Int_val(vport));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "open");
  return Val_unit;
}

CAMLprim
value otoky_rdb_optimize(value vrdb, value vparams, value vunit)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdboptimize(rdbw->rdb, string_option(vparams));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "optimize");
  return Val_unit;
}

CAMLprim
value otoky_rdb_out(value vrdb, value vkey, value vlen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbout(rdbw->rdb, String_val(vkey), Int_val(vlen));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "out");
  return Val_unit;
}

CAMLprim
value otoky_rdb_put(value vrdb, value vkey, value vkeylen, value vval, value vvallen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbput(rdbw->rdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "put");
  return Val_unit;
}

CAMLprim
value otoky_rdb_putcat(value vrdb, value vkey, value vkeylen, value vval, value vvallen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbputcat(rdbw->rdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "putcat");
  return Val_unit;
}

CAMLprim
value otoky_rdb_putkeep(value vrdb, value vkey, value vkeylen, value vval, value vvallen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbputkeep(rdbw->rdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "putkeep");
  return Val_unit;
}

CAMLprim
value otoky_rdb_putnr(value vrdb, value vkey, value vkeylen, value vval, value vvallen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbputnr(rdbw->rdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "putnr");
  return Val_unit;
}

CAMLprim
value otoky_rdb_putshl(value vrdb, value vwidth, value vkey, value vkeylen, value vval, value vvallen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbputshl(rdbw->rdb, String_val(vkey), Int_val(vkeylen), String_val(vval), Int_val(vvallen), int_option0(vwidth));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "putnr");
  return Val_unit;
}

CAMLprim
value otoky_rdb_putshl_bc(value *argv, int argn)
{
  return otoky_rdb_putshl(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim
value otoky_rdb_rnum(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcrdbrnum(rdbw->rdb);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "rnum");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_rdb_size(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  uint64_t r;
  caml_enter_blocking_section();
  r = tcrdbsize(rdbw->rdb);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "size");
  return caml_copy_int64(r);
}

CAMLprim
value otoky_rdb_stat(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  char *r;
  caml_enter_blocking_section();
  r = tcrdbstat(rdbw->rdb);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "stat");
  return caml_copy_string(r);
}

CAMLprim
value otoky_rdb_sync(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbsync(rdbw->rdb);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "sync");
  return Val_unit;
}

enum topt { Trecon };

static int topts_int_of_list(value v)
{
  if (v == Val_int(0))
    return 0;
  else {
    int topt = 0;
    for (v = Field(v, 0); v != Val_int(0); v = Field(v, 1)) {
      switch (Int_val(Field(v, 0))) {
      case Trecon: topt |= RDBTRECON; break;
      }
    }
    return topt;
  }
}

CAMLprim
value otoky_rdb_tune(value vrdb, value vtimeout, value vtopts, value vunit)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbtune(rdbw->rdb, double_option(vtimeout), topts_int_of_list(vtopts));
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "tune");
  return Val_unit;
}

CAMLprim
value otoky_rdb_vanish(value vrdb)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  bool r;
  caml_enter_blocking_section();
  r = tcrdbvanish(rdbw->rdb);
  caml_leave_blocking_section();
  if (!r) rdb_error(rdbw, "vanish");
  return Val_unit;
}

CAMLprim
value otoky_rdb_vsiz(value vrdb, value vkey, value vkeylen)
{
  rdb_wrap *rdbw = rdb_wrap_val(vrdb);
  int r;
  caml_enter_blocking_section();
  r = tcrdbvsiz(rdbw->rdb, String_val(vkey), Int_val(vkeylen));
  caml_leave_blocking_section();
  if (r == -1) rdb_error(rdbw, "vsiz");
  return Val_int(r);
}
