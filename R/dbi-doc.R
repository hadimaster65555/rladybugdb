#' LadybugDB DBI methods
#'
#' LadybugDB implements the standard DBI lifecycle, query, binding, fetch,
#' transaction, quoting, and table-metadata generics. LadybugDB's native schema
#' distinguishes node and relationship tables, so relational helpers outside
#' this documented subset are intentionally left to graph-specific Cypher and
#' the `lb_*` API. SQL `SELECT`, `dbWriteTable()`, and `dbAppendTable()` are not
#' translated. `dbExecute()` returns zero after successful DDL/DML because the
#' LadybugDB 0.20.4 C result summary does not expose a stable affected-row
#' count. Applicable driver behavior is exercised with a focused DBItest
#' subset.
#'
#' @name LadybugDB-DBI-methods
#' @aliases dbBegin,LadybugConnection-method
#' @aliases dbBind,LadybugResult-method
#' @aliases dbClearResult,LadybugResult-method
#' @aliases dbColumnInfo,LadybugResult-method
#' @aliases dbCommit,LadybugConnection-method
#' @aliases dbConnect,LadybugDriver-method
#' @aliases dbDataType,LadybugDriver-method
#' @aliases dbDisconnect,LadybugConnection-method
#' @aliases dbExecute,LadybugConnection,character-method
#' @aliases dbExistsTable,LadybugConnection,character-method
#' @aliases dbFetch,LadybugResult-method
#' @aliases dbGetInfo,LadybugConnection-method
#' @aliases dbGetInfo,LadybugDriver-method
#' @aliases dbGetInfo,LadybugResult-method
#' @aliases dbGetQuery,LadybugConnection,character-method
#' @aliases dbGetRowCount,LadybugResult-method
#' @aliases dbGetRowsAffected,LadybugResult-method
#' @aliases dbHasCompleted,LadybugResult-method
#' @aliases dbIsReadOnly,LadybugConnection-method
#' @aliases dbIsValid,LadybugConnection-method
#' @aliases dbIsValid,LadybugDriver-method
#' @aliases dbIsValid,LadybugResult-method
#' @aliases dbListFields,LadybugConnection,character-method
#' @aliases dbListTables,LadybugConnection-method
#' @aliases dbQuoteIdentifier,LadybugConnection,character-method
#' @aliases dbQuoteString,LadybugConnection,character-method
#' @aliases dbRollback,LadybugConnection-method
#' @aliases dbSendQuery,LadybugConnection,character-method
#' @aliases dbSendStatement,LadybugConnection,character-method
#' @aliases dbUnloadDriver,LadybugDriver-method
#' @aliases show,LadybugConnection-method
#' @aliases show,LadybugDriver-method
#' @aliases show,LadybugResult-method
#' @seealso [Ladybug()], [DBI::DBI-package]
NULL
