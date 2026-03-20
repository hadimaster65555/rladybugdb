// rladybugdb.cpp — Native Rcpp bindings to the LadybugDB C API (lbug.h v0.15+)
//
// All C API calls use output-pointer style: lbug_foo_get_bar(obj, &out).
// Strings returned by the library must be freed with lbug_destroy_string().

#include <Rcpp.h>
#include <lbug.h>
#include <string>
#include <vector>
#include <cstdint>

using namespace Rcpp;

// ---------------------------------------------------------------------------
// Helper: extract lbug_data_type_id from a lbug_value (get + destroy type)
// ---------------------------------------------------------------------------
static lbug_data_type_id value_type_id(lbug_value* val) {
  lbug_logical_type lt;
  lbug_value_get_data_type(val, &lt);
  lbug_data_type_id id = lbug_data_type_get_id(&lt);
  lbug_data_type_destroy(&lt);
  return id;
}

// ---------------------------------------------------------------------------
// Forward declaration
// ---------------------------------------------------------------------------
static SEXP lbug_value_to_r(lbug_value* val);

// ---------------------------------------------------------------------------
// Internal ID → R list(table=, offset=)  (matches graph.R heuristic)
// ---------------------------------------------------------------------------
static SEXP internal_id_to_r(lbug_value* id_val) {
  lbug_internal_id_t iid;
  lbug_value_get_internal_id(id_val, &iid);
  return List::create(Named("table")  = (double)iid.table_id,
                      Named("offset") = (double)iid.offset);
}

// ---------------------------------------------------------------------------
// Convert a single lbug_value* → R SEXP
// ---------------------------------------------------------------------------
static SEXP lbug_value_to_r(lbug_value* val) {
  if (lbug_value_is_null(val)) return R_NilValue;

  lbug_data_type_id tid = value_type_id(val);

  switch (tid) {

    case LBUG_BOOL: {
      bool v = false;
      lbug_value_get_bool(val, &v);
      return Rf_ScalarLogical(v ? 1 : 0);
    }

    case LBUG_INT8: {
      int8_t v = 0;
      lbug_value_get_int8(val, &v);
      return Rf_ScalarInteger((int)v);
    }
    case LBUG_INT16: {
      int16_t v = 0;
      lbug_value_get_int16(val, &v);
      return Rf_ScalarInteger((int)v);
    }
    case LBUG_INT32: {
      int32_t v = 0;
      lbug_value_get_int32(val, &v);
      return Rf_ScalarInteger(v);
    }
    case LBUG_INT64:
    case LBUG_SERIAL: {
      int64_t v = 0;
      lbug_value_get_int64(val, &v);
      return Rf_ScalarReal((double)v);
    }
    case LBUG_UINT8: {
      uint8_t v = 0;
      lbug_value_get_uint8(val, &v);
      return Rf_ScalarInteger((int)v);
    }
    case LBUG_UINT16: {
      uint16_t v = 0;
      lbug_value_get_uint16(val, &v);
      return Rf_ScalarInteger((int)v);
    }
    case LBUG_UINT32: {
      uint32_t v = 0;
      lbug_value_get_uint32(val, &v);
      return Rf_ScalarReal((double)v);
    }
    case LBUG_UINT64: {
      uint64_t v = 0;
      lbug_value_get_uint64(val, &v);
      return Rf_ScalarReal((double)v);
    }

    case LBUG_FLOAT: {
      float v = 0.0f;
      lbug_value_get_float(val, &v);
      return Rf_ScalarReal((double)v);
    }
    case LBUG_DOUBLE: {
      double v = 0.0;
      lbug_value_get_double(val, &v);
      return Rf_ScalarReal(v);
    }

    case LBUG_STRING:
    case LBUG_UUID: {
      char* s = nullptr;
      lbug_value_get_string(val, &s);
      SEXP out = Rf_mkString(s ? s : "");
      if (s) lbug_destroy_string(s);
      return out;
    }

    case LBUG_BLOB: {
      // Serialize to string representation
      char* s = lbug_value_to_string(val);
      SEXP out = Rf_mkString(s ? s : "");
      if (s) lbug_destroy_string(s);
      return out;
    }

    case LBUG_DATE: {
      lbug_date_t d = {0};
      lbug_value_get_date(val, &d);
      SEXP out = Rf_ScalarReal((double)d.days);
      Rf_setAttrib(out, R_ClassSymbol, Rf_mkString("Date"));
      return out;
    }

    case LBUG_TIMESTAMP:
    case LBUG_TIMESTAMP_TZ: {
      lbug_timestamp_t ts = {0};
      lbug_value_get_timestamp(val, &ts);
      double secs = (double)ts.value / 1e6;
      SEXP out = Rf_ScalarReal(secs);
      SEXP cls = PROTECT(Rf_allocVector(STRSXP, 2));
      SET_STRING_ELT(cls, 0, Rf_mkChar("POSIXct"));
      SET_STRING_ELT(cls, 1, Rf_mkChar("POSIXt"));
      Rf_setAttrib(out, R_ClassSymbol, cls);
      UNPROTECT(1);
      return out;
    }
    case LBUG_TIMESTAMP_NS: {
      lbug_timestamp_ns_t ts = {0};
      lbug_value_get_timestamp_ns(val, &ts);
      double secs = (double)ts.value / 1e9;
      SEXP out = Rf_ScalarReal(secs);
      SEXP cls = PROTECT(Rf_allocVector(STRSXP, 2));
      SET_STRING_ELT(cls, 0, Rf_mkChar("POSIXct"));
      SET_STRING_ELT(cls, 1, Rf_mkChar("POSIXt"));
      Rf_setAttrib(out, R_ClassSymbol, cls);
      UNPROTECT(1);
      return out;
    }
    case LBUG_TIMESTAMP_MS: {
      lbug_timestamp_ms_t ts = {0};
      lbug_value_get_timestamp_ms(val, &ts);
      double secs = (double)ts.value / 1e3;
      SEXP out = Rf_ScalarReal(secs);
      SEXP cls = PROTECT(Rf_allocVector(STRSXP, 2));
      SET_STRING_ELT(cls, 0, Rf_mkChar("POSIXct"));
      SET_STRING_ELT(cls, 1, Rf_mkChar("POSIXt"));
      Rf_setAttrib(out, R_ClassSymbol, cls);
      UNPROTECT(1);
      return out;
    }
    case LBUG_TIMESTAMP_SEC: {
      lbug_timestamp_sec_t ts = {0};
      lbug_value_get_timestamp_sec(val, &ts);
      double secs = (double)ts.value;
      SEXP out = Rf_ScalarReal(secs);
      SEXP cls = PROTECT(Rf_allocVector(STRSXP, 2));
      SET_STRING_ELT(cls, 0, Rf_mkChar("POSIXct"));
      SET_STRING_ELT(cls, 1, Rf_mkChar("POSIXt"));
      Rf_setAttrib(out, R_ClassSymbol, cls);
      UNPROTECT(1);
      return out;
    }

    case LBUG_INTERVAL: {
      char* s = lbug_value_to_string(val);
      SEXP out = Rf_mkString(s ? s : "");
      if (s) lbug_destroy_string(s);
      return out;
    }

    case LBUG_INTERNAL_ID: {
      return internal_id_to_r(val);
    }

    case LBUG_LIST:
    case LBUG_ARRAY: {
      uint64_t n = 0;
      lbug_value_get_list_size(val, &n);
      List lst(n);
      for (uint64_t i = 0; i < n; i++) {
        lbug_value elem;
        lbug_value_get_list_element(val, i, &elem);
        lst[i] = lbug_value_to_r(&elem);
      }
      return lst;
    }

    case LBUG_MAP: {
      uint64_t n = 0;
      lbug_value_get_map_size(val, &n);
      List keys(n), vals(n);
      for (uint64_t i = 0; i < n; i++) {
        lbug_value k, v;
        lbug_value_get_map_key(val, i, &k);
        lbug_value_get_map_value(val, i, &v);
        keys[i] = lbug_value_to_r(&k);
        vals[i] = lbug_value_to_r(&v);
      }
      return List::create(Named("keys") = keys, Named("values") = vals);
    }

    case LBUG_STRUCT: {
      uint64_t n = 0;
      lbug_value_get_struct_num_fields(val, &n);
      List out(n);
      CharacterVector nms(n);
      for (uint64_t i = 0; i < n; i++) {
        char* fname = nullptr;
        lbug_value_get_struct_field_name(val, i, &fname);
        nms[i] = fname ? fname : "";
        if (fname) lbug_destroy_string(fname);
        lbug_value fval;
        lbug_value_get_struct_field_value(val, i, &fval);
        out[i] = lbug_value_to_r(&fval);
      }
      out.names() = nms;
      return out;
    }

    case LBUG_NODE: {
      // _ID: list(table=, offset=)
      // _LABEL: string
      // property keys...
      lbug_value id_val;
      lbug_node_val_get_id_val(val, &id_val);
      SEXP id_r = internal_id_to_r(&id_val);

      lbug_value label_val;
      lbug_node_val_get_label_val(val, &label_val);
      char* label_str = nullptr;
      lbug_value_get_string(&label_val, &label_str);
      std::string label = label_str ? label_str : "";
      if (label_str) lbug_destroy_string(label_str);

      uint64_t np = 0;
      lbug_node_val_get_property_size(val, &np);

      List out(2 + np);
      CharacterVector nms(2 + np);
      nms[0] = "_ID";
      nms[1] = "_LABEL";
      out[0] = id_r;
      out[1] = label;

      for (uint64_t i = 0; i < np; i++) {
        char* pname = nullptr;
        lbug_node_val_get_property_name_at(val, i, &pname);
        nms[2 + i] = pname ? pname : "";
        if (pname) lbug_destroy_string(pname);
        lbug_value pval;
        lbug_node_val_get_property_value_at(val, i, &pval);
        out[2 + i] = lbug_value_to_r(&pval);
      }
      out.names() = nms;
      return out;
    }

    case LBUG_REL: {
      // _SRC, _DST, _LABEL, _ID, properties...
      lbug_value src_val, dst_val, id_val, label_val;
      lbug_rel_val_get_src_id_val(val, &src_val);
      lbug_rel_val_get_dst_id_val(val, &dst_val);
      lbug_rel_val_get_id_val(val, &id_val);
      lbug_rel_val_get_label_val(val, &label_val);

      char* label_str = nullptr;
      lbug_value_get_string(&label_val, &label_str);
      std::string label = label_str ? label_str : "";
      if (label_str) lbug_destroy_string(label_str);

      uint64_t np = 0;
      lbug_rel_val_get_property_size(val, &np);

      List out(4 + np);
      CharacterVector nms(4 + np);
      nms[0] = "_SRC";
      nms[1] = "_DST";
      nms[2] = "_LABEL";
      nms[3] = "_ID";
      out[0] = internal_id_to_r(&src_val);
      out[1] = internal_id_to_r(&dst_val);
      out[2] = label;
      out[3] = internal_id_to_r(&id_val);

      for (uint64_t i = 0; i < np; i++) {
        char* pname = nullptr;
        lbug_rel_val_get_property_name_at(val, i, &pname);
        nms[4 + i] = pname ? pname : "";
        if (pname) lbug_destroy_string(pname);
        lbug_value pval;
        lbug_rel_val_get_property_value_at(val, i, &pval);
        out[4 + i] = lbug_value_to_r(&pval);
      }
      out.names() = nms;
      return out;
    }

    default: {
      char* s = lbug_value_to_string(val);
      SEXP out = Rf_mkString(s ? s : "");
      if (s) lbug_destroy_string(s);
      return out;
    }
  }
}

// ---------------------------------------------------------------------------
// External pointer wrappers (RAII around C handles)
// ---------------------------------------------------------------------------

struct LbDatabase {
  lbug_database handle;
  bool closed = false;
  ~LbDatabase() {
    if (!closed) {
      lbug_database_destroy(&handle);
      closed = true;
    }
  }
};

struct LbConnection {
  lbug_connection handle;
  Rcpp::XPtr<LbDatabase> db_ref;
  bool closed = false;
  explicit LbConnection(Rcpp::XPtr<LbDatabase> db) : db_ref(db) {}
  ~LbConnection() {
    if (!closed) {
      lbug_connection_destroy(&handle);
      closed = true;
    }
  }
};

struct LbResult {
  lbug_query_result handle;
  Rcpp::XPtr<LbConnection> conn_ref;
  bool closed = false;
  explicit LbResult(Rcpp::XPtr<LbConnection> conn) : conn_ref(conn) {}
  ~LbResult() {
    if (!closed) {
      lbug_query_result_destroy(&handle);
      closed = true;
    }
  }
};

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

// [[Rcpp::export]]
SEXP lb_database_open(std::string path, bool read_only) {
  LbDatabase* db = new LbDatabase();
  lbug_system_config cfg = lbug_default_system_config();
  cfg.read_only = read_only;
  lbug_state st = lbug_database_init(path.c_str(), cfg, &db->handle);
  if (st != LbugSuccess) {
    delete db;
    Rcpp::stop("Failed to open database: %s", path.c_str());
  }
  return Rcpp::XPtr<LbDatabase>(db, true);
}

// [[Rcpp::export]]
void lb_database_close(SEXP db_xptr) {
  Rcpp::XPtr<LbDatabase> xptr(db_xptr);
  if (!xptr->closed) {
    lbug_database_destroy(&xptr->handle);
    xptr->closed = true;
  }
}

// [[Rcpp::export]]
std::string lb_database_version() {
  char* v = lbug_get_version();
  std::string out = v ? v : "unknown";
  // lbug_get_version returns a static string — do not destroy
  return out;
}

// ---------------------------------------------------------------------------
// Connection
// ---------------------------------------------------------------------------

// [[Rcpp::export]]
SEXP lb_connection_create(SEXP db_xptr, int num_threads) {
  Rcpp::XPtr<LbDatabase> db(db_xptr);
  if (db->closed) Rcpp::stop("Database has been closed.");

  LbConnection* conn = new LbConnection(db);
  lbug_state st = lbug_connection_init(&db->handle, &conn->handle);
  if (st != LbugSuccess) {
    delete conn;
    Rcpp::stop("Failed to create connection.");
  }
  if (num_threads > 0) {
    lbug_connection_set_max_num_thread_for_exec(&conn->handle, (uint64_t)num_threads);
  }
  return Rcpp::XPtr<LbConnection>(conn, true);
}

// [[Rcpp::export]]
void lb_connection_close(SEXP conn_xptr) {
  Rcpp::XPtr<LbConnection> xptr(conn_xptr);
  if (!xptr->closed) {
    lbug_connection_destroy(&xptr->handle);
    xptr->closed = true;
  }
}

// ---------------------------------------------------------------------------
// Execute
// ---------------------------------------------------------------------------

// [[Rcpp::export]]
SEXP lb_connection_execute(SEXP conn_xptr, std::string query) {
  Rcpp::XPtr<LbConnection> conn(conn_xptr);
  if (conn->closed) Rcpp::stop("Connection has been closed.");

  LbResult* res = new LbResult(conn);
  lbug_state st = lbug_connection_query(&conn->handle, query.c_str(), &res->handle);
  if (st != LbugSuccess) {
    // Query state error — check result for message
    char* errmsg = lbug_query_result_get_error_message(&res->handle);
    std::string msg = errmsg ? errmsg : "Unknown query error";
    if (errmsg) lbug_destroy_string(errmsg);
    lbug_query_result_destroy(&res->handle);
    res->closed = true;
    delete res;
    Rcpp::stop(msg);
  }
  if (!lbug_query_result_is_success(&res->handle)) {
    char* errmsg = lbug_query_result_get_error_message(&res->handle);
    std::string msg = errmsg ? errmsg : "Query failed";
    if (errmsg) lbug_destroy_string(errmsg);
    lbug_query_result_destroy(&res->handle);
    res->closed = true;
    delete res;
    Rcpp::stop(msg);
  }
  return Rcpp::XPtr<LbResult>(res, true);
}

// [[Rcpp::export]]
SEXP lb_connection_execute_params(SEXP conn_xptr, std::string query,
                                  Rcpp::List params) {
  Rcpp::XPtr<LbConnection> conn(conn_xptr);
  if (conn->closed) Rcpp::stop("Connection has been closed.");

  lbug_prepared_statement stmt;
  lbug_state st = lbug_connection_prepare(&conn->handle, query.c_str(), &stmt);
  if (st != LbugSuccess || !lbug_prepared_statement_is_success(&stmt)) {
    char* errmsg = lbug_prepared_statement_get_error_message(&stmt);
    std::string msg = errmsg ? errmsg : "Prepare failed";
    if (errmsg) lbug_destroy_string(errmsg);
    lbug_prepared_statement_destroy(&stmt);
    Rcpp::stop(msg);
  }

  CharacterVector names = params.names();
  for (int i = 0; i < params.size(); i++) {
    std::string pname = Rcpp::as<std::string>(names[i]);
    SEXP pval = params[i];

    if (Rf_isLogical(pval) && LENGTH(pval) == 1) {
      bool bv = (LOGICAL(pval)[0] == 1);
      lbug_prepared_statement_bind_bool(&stmt, pname.c_str(), bv);
    } else if (Rf_isInteger(pval) && LENGTH(pval) == 1) {
      lbug_prepared_statement_bind_int64(&stmt, pname.c_str(),
                                         (int64_t)INTEGER(pval)[0]);
    } else if (Rf_isReal(pval) && LENGTH(pval) == 1) {
      lbug_prepared_statement_bind_double(&stmt, pname.c_str(), REAL(pval)[0]);
    } else if (Rf_isString(pval) && LENGTH(pval) == 1) {
      lbug_prepared_statement_bind_string(&stmt, pname.c_str(),
                                          CHAR(STRING_ELT(pval, 0)));
    } else {
      lbug_prepared_statement_destroy(&stmt);
      Rcpp::stop("Unsupported parameter type for '%s'. "
                 "Use logical, integer, double, or character scalars.",
                 pname.c_str());
    }
  }

  LbResult* res = new LbResult(conn);
  st = lbug_connection_execute(&conn->handle, &stmt, &res->handle);
  lbug_prepared_statement_destroy(&stmt);

  if (st != LbugSuccess || !lbug_query_result_is_success(&res->handle)) {
    char* errmsg = lbug_query_result_get_error_message(&res->handle);
    std::string msg = errmsg ? errmsg : "Execute failed";
    if (errmsg) lbug_destroy_string(errmsg);
    lbug_query_result_destroy(&res->handle);
    res->closed = true;
    delete res;
    Rcpp::stop(msg);
  }
  return Rcpp::XPtr<LbResult>(res, true);
}

// ---------------------------------------------------------------------------
// Result metadata
// ---------------------------------------------------------------------------

// [[Rcpp::export]]
int lb_result_num_tuples(SEXP res_xptr) {
  Rcpp::XPtr<LbResult> res(res_xptr);
  return (int)lbug_query_result_get_num_tuples(&res->handle);
}

// [[Rcpp::export]]
Rcpp::CharacterVector lb_result_column_names(SEXP res_xptr) {
  Rcpp::XPtr<LbResult> res(res_xptr);
  uint64_t nc = lbug_query_result_get_num_columns(&res->handle);
  CharacterVector out(nc);
  for (uint64_t i = 0; i < nc; i++) {
    char* name = nullptr;
    lbug_query_result_get_column_name(&res->handle, i, &name);
    out[i] = name ? name : "";
    if (name) lbug_destroy_string(name);
  }
  return out;
}

// [[Rcpp::export]]
Rcpp::CharacterVector lb_result_column_types(SEXP res_xptr) {
  Rcpp::XPtr<LbResult> res(res_xptr);
  uint64_t nc = lbug_query_result_get_num_columns(&res->handle);
  CharacterVector out(nc);
  for (uint64_t i = 0; i < nc; i++) {
    lbug_logical_type lt;
    lbug_query_result_get_column_data_type(&res->handle, i, &lt);
    lbug_data_type_id tid = lbug_data_type_get_id(&lt);
    lbug_data_type_destroy(&lt);
    switch (tid) {
      case LBUG_BOOL:          out[i] = "BOOL";      break;
      case LBUG_INT8:          out[i] = "INT8";       break;
      case LBUG_INT16:         out[i] = "INT16";      break;
      case LBUG_INT32:         out[i] = "INT32";      break;
      case LBUG_INT64:         out[i] = "INT64";      break;
      case LBUG_UINT8:         out[i] = "UINT8";      break;
      case LBUG_UINT16:        out[i] = "UINT16";     break;
      case LBUG_UINT32:        out[i] = "UINT32";     break;
      case LBUG_UINT64:        out[i] = "UINT64";     break;
      case LBUG_SERIAL:        out[i] = "SERIAL";     break;
      case LBUG_FLOAT:         out[i] = "FLOAT";      break;
      case LBUG_DOUBLE:        out[i] = "DOUBLE";     break;
      case LBUG_STRING:        out[i] = "STRING";     break;
      case LBUG_BLOB:          out[i] = "BLOB";       break;
      case LBUG_UUID:          out[i] = "UUID";       break;
      case LBUG_DATE:          out[i] = "DATE";       break;
      case LBUG_TIMESTAMP:     out[i] = "TIMESTAMP";  break;
      case LBUG_TIMESTAMP_NS:  out[i] = "TIMESTAMP_NS"; break;
      case LBUG_TIMESTAMP_MS:  out[i] = "TIMESTAMP_MS"; break;
      case LBUG_TIMESTAMP_SEC: out[i] = "TIMESTAMP_SEC"; break;
      case LBUG_TIMESTAMP_TZ:  out[i] = "TIMESTAMP_TZ";  break;
      case LBUG_INTERVAL:      out[i] = "INTERVAL";   break;
      case LBUG_INTERNAL_ID:   out[i] = "INTERNAL_ID"; break;
      case LBUG_LIST:          out[i] = "LIST";       break;
      case LBUG_ARRAY:         out[i] = "ARRAY";      break;
      case LBUG_STRUCT:        out[i] = "STRUCT";     break;
      case LBUG_MAP:           out[i] = "MAP";        break;
      case LBUG_NODE:          out[i] = "NODE";       break;
      case LBUG_REL:           out[i] = "REL";        break;
      default:                 out[i] = "UNKNOWN";    break;
    }
  }
  return out;
}

// [[Rcpp::export]]
void lb_result_close(SEXP res_xptr) {
  Rcpp::XPtr<LbResult> res(res_xptr);
  if (!res->closed) {
    lbug_query_result_destroy(&res->handle);
    res->closed = true;
  }
}

// ---------------------------------------------------------------------------
// Main result fetch — column-oriented, single pass
// ---------------------------------------------------------------------------

// [[Rcpp::export]]
Rcpp::List lb_result_fetch_all(SEXP res_xptr) {
  Rcpp::XPtr<LbResult> res(res_xptr);

  uint64_t nc   = lbug_query_result_get_num_columns(&res->handle);
  uint64_t nrow = lbug_query_result_get_num_tuples(&res->handle);

  // Collect column names and type IDs
  std::vector<lbug_data_type_id> col_tids(nc);
  CharacterVector col_names(nc);
  for (uint64_t c = 0; c < nc; c++) {
    char* cname = nullptr;
    lbug_query_result_get_column_name(&res->handle, c, &cname);
    col_names[c] = cname ? cname : "";
    if (cname) lbug_destroy_string(cname);

    lbug_logical_type lt;
    lbug_query_result_get_column_data_type(&res->handle, c, &lt);
    col_tids[c] = lbug_data_type_get_id(&lt);
    lbug_data_type_destroy(&lt);
  }

  // Pre-allocate columns with the correct R type (NA-filled)
  List out(nc);
  out.names() = col_names;
  for (uint64_t c = 0; c < nc; c++) {
    switch (col_tids[c]) {
      case LBUG_BOOL:
        out[c] = LogicalVector(nrow, NA_LOGICAL);
        break;
      case LBUG_INT8: case LBUG_INT16: case LBUG_INT32:
      case LBUG_UINT8: case LBUG_UINT16:
        out[c] = IntegerVector(nrow, NA_INTEGER);
        break;
      case LBUG_INT64: case LBUG_UINT32: case LBUG_UINT64:
      case LBUG_SERIAL: case LBUG_FLOAT: case LBUG_DOUBLE: {
        out[c] = NumericVector(nrow, NA_REAL);
        break;
      }
      case LBUG_DATE: {
        NumericVector v(nrow, NA_REAL);
        v.attr("class") = "Date";
        out[c] = v;
        break;
      }
      case LBUG_TIMESTAMP: case LBUG_TIMESTAMP_TZ:
      case LBUG_TIMESTAMP_NS: case LBUG_TIMESTAMP_MS: case LBUG_TIMESTAMP_SEC: {
        NumericVector v(nrow, NA_REAL);
        v.attr("class") = CharacterVector::create("POSIXct", "POSIXt");
        out[c] = v;
        break;
      }
      case LBUG_STRING: case LBUG_BLOB: case LBUG_UUID:
      case LBUG_INTERVAL: case LBUG_DECIMAL:
        out[c] = CharacterVector(nrow, NA_STRING);
        break;
      default:
        // NODE, REL, LIST, ARRAY, STRUCT, MAP, INTERNAL_ID, etc.
        out[c] = List(nrow);
        break;
    }
  }

  // Iterate rows — each call to get_next reuses the tuple buffer
  uint64_t row = 0;
  while (lbug_query_result_has_next(&res->handle)) {
    lbug_flat_tuple tuple;
    lbug_query_result_get_next(&res->handle, &tuple);

    for (uint64_t c = 0; c < nc; c++) {
      lbug_value val;
      lbug_flat_tuple_get_value(&tuple, c, &val);

      if (lbug_value_is_null(&val)) {
        // Already pre-filled with NA — nothing to do
      } else {
        switch (col_tids[c]) {
          case LBUG_BOOL: {
            bool v = false;
            lbug_value_get_bool(&val, &v);
            LOGICAL(out[c])[row] = v ? 1 : 0;
            break;
          }
          case LBUG_INT8: {
            int8_t v = 0;
            lbug_value_get_int8(&val, &v);
            INTEGER(out[c])[row] = (int)v;
            break;
          }
          case LBUG_INT16: {
            int16_t v = 0;
            lbug_value_get_int16(&val, &v);
            INTEGER(out[c])[row] = (int)v;
            break;
          }
          case LBUG_INT32: {
            int32_t v = 0;
            lbug_value_get_int32(&val, &v);
            INTEGER(out[c])[row] = v;
            break;
          }
          case LBUG_UINT8: {
            uint8_t v = 0;
            lbug_value_get_uint8(&val, &v);
            INTEGER(out[c])[row] = (int)v;
            break;
          }
          case LBUG_UINT16: {
            uint16_t v = 0;
            lbug_value_get_uint16(&val, &v);
            INTEGER(out[c])[row] = (int)v;
            break;
          }
          case LBUG_INT64: case LBUG_SERIAL: {
            int64_t v = 0;
            lbug_value_get_int64(&val, &v);
            REAL(out[c])[row] = (double)v;
            break;
          }
          case LBUG_UINT32: {
            uint32_t v = 0;
            lbug_value_get_uint32(&val, &v);
            REAL(out[c])[row] = (double)v;
            break;
          }
          case LBUG_UINT64: {
            uint64_t v = 0;
            lbug_value_get_uint64(&val, &v);
            REAL(out[c])[row] = (double)v;
            break;
          }
          case LBUG_FLOAT: {
            float v = 0.0f;
            lbug_value_get_float(&val, &v);
            REAL(out[c])[row] = (double)v;
            break;
          }
          case LBUG_DOUBLE: {
            double v = 0.0;
            lbug_value_get_double(&val, &v);
            REAL(out[c])[row] = v;
            break;
          }
          case LBUG_DATE: {
            lbug_date_t d = {0};
            lbug_value_get_date(&val, &d);
            REAL(out[c])[row] = (double)d.days;
            break;
          }
          case LBUG_TIMESTAMP: case LBUG_TIMESTAMP_TZ: {
            lbug_timestamp_t ts = {0};
            lbug_value_get_timestamp(&val, &ts);
            REAL(out[c])[row] = (double)ts.value / 1e6;
            break;
          }
          case LBUG_TIMESTAMP_NS: {
            lbug_timestamp_ns_t ts = {0};
            lbug_value_get_timestamp_ns(&val, &ts);
            REAL(out[c])[row] = (double)ts.value / 1e9;
            break;
          }
          case LBUG_TIMESTAMP_MS: {
            lbug_timestamp_ms_t ts = {0};
            lbug_value_get_timestamp_ms(&val, &ts);
            REAL(out[c])[row] = (double)ts.value / 1e3;
            break;
          }
          case LBUG_TIMESTAMP_SEC: {
            lbug_timestamp_sec_t ts = {0};
            lbug_value_get_timestamp_sec(&val, &ts);
            REAL(out[c])[row] = (double)ts.value;
            break;
          }
          case LBUG_STRING: case LBUG_UUID: {
            char* s = nullptr;
            lbug_value_get_string(&val, &s);
            SET_STRING_ELT(out[c], row, Rf_mkChar(s ? s : ""));
            if (s) lbug_destroy_string(s);
            break;
          }
          case LBUG_BLOB: case LBUG_INTERVAL: case LBUG_DECIMAL: {
            char* s = lbug_value_to_string(&val);
            SET_STRING_ELT(out[c], row, Rf_mkChar(s ? s : ""));
            if (s) lbug_destroy_string(s);
            break;
          }
          default: {
            as<List>(out[c])[row] = lbug_value_to_r(&val);
            break;
          }
        }
      }
    }

    lbug_flat_tuple_destroy(&tuple);
    row++;
  }

  return out;
}
