#' Adverse Event Analysis Dataset (ADAE)
#'
#' @description `r lifecycle::badge("stable")`
#'
#' Function for generating random Adverse Event Analysis Dataset for a given
#' Subject-Level Analysis Dataset.
#'
#' @details One record per each record in the corresponding SDTM domain.
#'
#' Keys: `STUDYID`, `USUBJID`, `ASTDTM`, `AETERM`, `AESEQ`
#'
#' @inheritParams argument_convention
#' @param max_n_aes (`integer`)\cr Maximum number of AEs per patient. Defaults to 10.
#' @template param_cached
#' @templateVar data adae
#'
#' @return `data.frame`
#' @export
#'
#' @examples
#' library(random.cdisc.data)
#' adsl <- radsl(N = 10, study_duration = 2, seed = 1)
#'
#' adae <- radae(adsl, seed = 2)
#' adae
#'
#' # Add metadata.
#' aag <- utils::read.table(
#'   sep = ",", header = TRUE,
#'   text = paste(
#'     "NAMVAR,SRCVAR,GRPTYPE,REFNAME,REFTERM,SCOPE",
#'     "CQ01NAM,AEDECOD,CUSTOM,D.2.1.5.3/A.1.1.1.1 AESI,dcd D.2.1.5.3,",
#'     "CQ01NAM,AEDECOD,CUSTOM,D.2.1.5.3/A.1.1.1.1 AESI,dcd A.1.1.1.1,",
#'     "SMQ01NAM,AEDECOD,SMQ,C.1.1.1.3/B.2.2.3.1 AESI,dcd C.1.1.1.3,BROAD",
#'     "SMQ01NAM,AEDECOD,SMQ,C.1.1.1.3/B.2.2.3.1 AESI,dcd B.2.2.3.1,BROAD",
#'     "SMQ02NAM,AEDECOD,SMQ,Y.9.9.9.9/Z.9.9.9.9 AESI,dcd Y.9.9.9.9,NARROW",
#'     "SMQ02NAM,AEDECOD,SMQ,Y.9.9.9.9/Z.9.9.9.9 AESI,dcd Z.9.9.9.9,NARROW",
#'     sep = "\n"
#'   ), stringsAsFactors = FALSE
#' )
#'
#' adae <- radae(adsl, lookup_aag = aag)
#'
#' with(
#'   adae,
#'   cbind(
#'     table(AEDECOD, SMQ01NAM),
#'     table(AEDECOD, CQ01NAM)
#'   )
#' )
radae <- function(adsl,
                  max_n_aes = 10L,
                  lookup = NULL,
                  lookup_aag = NULL,
                  seed = NULL,
                  na_percentage = 0,
                  na_vars = list(
                    AEBODSYS = c(NA, 0.1),
                    AEDECOD = c(1234, 0.1),
                    AETOXGR = c(1234, 0.1)
                  ),
                  cached = FALSE) {
  checkmate::assert_flag(cached)
  if (cached) {
    return(get_cached_data("cadae"))
  }

  checkmate::assert_data_frame(adsl)
  checkmate::assert_integer(max_n_aes, len = 1, any.missing = FALSE)
  checkmate::assert_number(seed, null.ok = TRUE)
  checkmate::assert_number(na_percentage, lower = 0, upper = 1)
  checkmate::assert_true(na_percentage < 1)

  # check lookup parameters
  checkmate::assert_data_frame(lookup, null.ok = TRUE)
  lookup_ae <- if (!is.null(lookup)) {
    lookup
  } else {
    tibble::tribble(
      ~AEBODSYS, ~AELLT, ~AEDECOD, ~AEHLT, ~AEHLGT, ~AETOXGR, ~AESOC, ~AESER, ~AEREL,
      "cl A.1", "llt A.1.1.1.1", "dcd A.1.1.1.1", "hlt A.1.1.1", "hlgt A.1.1", "1", "cl A", "N", "N",
      "cl A.1", "llt A.1.1.1.2", "dcd A.1.1.1.2", "hlt A.1.1.1", "hlgt A.1.1", "2", "cl A", "Y", "N",
      "cl B.1", "llt B.1.1.1.1", "dcd B.1.1.1.1", "hlt B.1.1.1", "hlgt B.1.1", "5", "cl B", "Y", "Y",
      "cl B.2", "llt B.2.1.2.1", "dcd B.2.1.2.1", "hlt B.2.1.2", "hlgt B.2.1", "3", "cl B", "N", "N",
      "cl B.2", "llt B.2.2.3.1", "dcd B.2.2.3.1", "hlt B.2.2.3", "hlgt B.2.2", "1", "cl B", "Y", "N",
      "cl C.1", "llt C.1.1.1.3", "dcd C.1.1.1.3", "hlt C.1.1.1", "hlgt C.1.1", "4", "cl C", "N", "Y",
      "cl C.2", "llt C.2.1.2.1", "dcd C.2.1.2.1", "hlt C.2.1.2", "hlgt C.2.1", "2", "cl C", "N", "Y",
      "cl D.1", "llt D.1.1.1.1", "dcd D.1.1.1.1", "hlt D.1.1.1", "hlgt D.1.1", "5", "cl D", "Y", "Y",
      "cl D.1", "llt D.1.1.4.2", "dcd D.1.1.4.2", "hlt D.1.1.4", "hlgt D.1.1", "3", "cl D", "N", "N",
      "cl D.2", "llt D.2.1.5.3", "dcd D.2.1.5.3", "hlt D.2.1.5", "hlgt D.2.1", "1", "cl D", "N", "Y"
    )
  }

  checkmate::assert_data_frame(lookup_aag, null.ok = TRUE)
  aag <- if (!is.null(lookup_aag)) {
    lookup_aag
  } else {
    aag <- utils::read.table(
      sep = ",", header = TRUE,
      text = paste(
        "NAMVAR,SRCVAR,GRPTYPE,REFNAME,REFTERM,SCOPE",
        "CQ01NAM,AEDECOD,CUSTOM,D.2.1.5.3/A.1.1.1.1 AESI,dcd D.2.1.5.3,",
        "CQ01NAM,AEDECOD,CUSTOM,D.2.1.5.3/A.1.1.1.1 AESI,dcd A.1.1.1.1,",
        "SMQ01NAM,AEDECOD,SMQ,C.1.1.1.3/B.2.2.3.1 AESI,dcd C.1.1.1.3,BROAD",
        "SMQ01NAM,AEDECOD,SMQ,C.1.1.1.3/B.2.2.3.1 AESI,dcd B.2.2.3.1,BROAD",
        "SMQ02NAM,AEDECOD,SMQ,Y.9.9.9.9/Z.9.9.9.9 AESI,dcd Y.9.9.9.9,NARROW",
        "SMQ02NAM,AEDECOD,SMQ,Y.9.9.9.9/Z.9.9.9.9 AESI,dcd Z.9.9.9.9,NARROW",
        sep = "\n"
      ), stringsAsFactors = FALSE
    )
  }

  if (!is.null(seed)) set.seed(seed)
  study_duration_secs <- lubridate::seconds(attr(adsl, "study_duration_secs"))

  adae <- Map(
    function(id, sid) {
      n_aes <- sample(c(0, seq_len(max_n_aes)), 1)
      i <- sample(seq_len(nrow(lookup_ae)), n_aes, TRUE)
      dplyr::mutate(
        lookup_ae[i, ],
        USUBJID = id,
        STUDYID = sid
      )
    },
    adsl$USUBJID,
    adsl$STUDYID
  ) %>%
    Reduce(rbind, .) %>%
    `[`(c(10, 11, 1, 2, 3, 4, 5, 6, 7, 8, 9)) %>%
    dplyr::mutate(AETERM = gsub("dcd", "trm", AEDECOD)) %>%
    dplyr::mutate(AESEV = dplyr::case_when(
      AETOXGR == 1 ~ "MILD",
      AETOXGR %in% c(2, 3) ~ "MODERATE",
      AETOXGR %in% c(4, 5) ~ "SEVERE"
    ))

  adae <- var_relabel(
    adae,
    STUDYID = "Study Identifier",
    USUBJID = "Unique Subject Identifier"
  )

  # merge adsl to be able to add AE date and study day variables
  adae <- dplyr::inner_join(adae, adsl, by = c("STUDYID", "USUBJID")) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(TRTENDT = lubridate::date(dplyr::case_when(
      is.na(TRTEDTM) ~ lubridate::floor_date(lubridate::date(TRTSDTM) + study_duration_secs, unit = "day"),
      TRUE ~ TRTEDTM
    ))) %>%
    dplyr::mutate(ASTDTM = sample(
      seq(lubridate::as_datetime(TRTSDTM), lubridate::as_datetime(TRTENDT), by = "day"),
      size = 1
    )) %>%
    dplyr::mutate(ASTDY = ceiling(difftime(ASTDTM, TRTSDTM, units = "days"))) %>%
    # add 1 to end of range incase both values passed to sample() are the same
    dplyr::mutate(AENDTM = sample(
      seq(lubridate::as_datetime(ASTDTM), lubridate::as_datetime(TRTENDT + 1), by = "day"),
      size = 1
    )) %>%
    dplyr::mutate(AENDY = ceiling(difftime(AENDTM, TRTSDTM, units = "days"))) %>%
    dplyr::mutate(LDOSEDTM = dplyr::case_when(
      TRTSDTM < ASTDTM ~ lubridate::as_datetime(stats::runif(1, TRTSDTM, ASTDTM)),
      TRUE ~ ASTDTM
    )) %>%
    dplyr::mutate(LDRELTM = as.numeric(difftime(ASTDTM, LDOSEDTM, units = "mins"))) %>%
    dplyr::select(-TRTENDT) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(STUDYID, USUBJID, ASTDTM, AETERM)

  adae <- adae %>%
    dplyr::group_by(USUBJID) %>%
    dplyr::mutate(AESEQ = seq_len(dplyr::n())) %>%
    dplyr::mutate(ASEQ = AESEQ) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(
      STUDYID,
      USUBJID,
      ASTDTM,
      AETERM,
      AESEQ
    )

  outcomes <- c(
    "UNKNOWN",
    "NOT RECOVERED/NOT RESOLVED",
    "RECOVERED/RESOLVED WITH SEQUELAE",
    "RECOVERING/RESOLVING",
    "RECOVERED/RESOLVED"
  )

  actions <- c(
    "DOSE RATE REDUCED",
    "UNKNOWN",
    "NOT APPLICABLE",
    "DRUG INTERRUPTED",
    "DRUG WITHDRAWN",
    "DOSE INCREASED",
    "DOSE NOT CHANGED",
    "DOSE REDUCED",
    "NOT EVALUABLE"
  )

  adae <- adae %>%
    dplyr::mutate(AEOUT = factor(ifelse(
      AETOXGR == "5",
      "FATAL",
      as.character(sample_fct(outcomes, nrow(adae), prob = c(0.1, 0.2, 0.1, 0.3, 0.3)))
    ))) %>%
    dplyr::mutate(AEACN = factor(ifelse(
      AETOXGR == "5",
      "NOT EVALUABLE",
      as.character(sample_fct(actions, nrow(adae), prob = c(0.05, 0.05, 0.05, 0.01, 0.05, 0.1, 0.45, 0.1, 0.05)))
    ))) %>%
    dplyr::mutate(AESDTH = dplyr::case_when(
      AEOUT == "FATAL" ~ "Y",
      TRUE ~ "N"
    )) %>%
    dplyr::mutate(TRTEMFL = ifelse(ASTDTM >= TRTSDTM, "Y", "")) %>%
    dplyr::mutate(AECONTRT = sample(c("Y", "N"), prob = c(0.4, 0.6), size = dplyr::n(), replace = TRUE)) %>%
    dplyr::mutate(
      ANL01FL = ifelse(TRTEMFL == "Y" & ASTDTM <= TRTEDTM + lubridate::month(1), "Y", "")
    ) %>%
    dplyr::mutate(ANL01FL = ifelse(is.na(ANL01FL), "", ANL01FL))

  adae <- adae %>%
    dplyr::mutate(AERELNST = sample(c("Y", "N"), prob = c(0.4, 0.6), size = dplyr::n(), replace = TRUE)) %>%
    dplyr::mutate(AEACNOTH = sample(
      x = c("MEDICATION", "PROCEDURE/SURGERY", "SUBJECT DISCONTINUED FROM STUDY", "NONE"),
      prob = c(0.2, 0.4, 0.2, 0.2),
      size = dplyr::n(),
      replace = TRUE
    ))

  # Split metadata for AEs of special interest (AESI).
  l_aag <- split(aag, interaction(aag$NAMVAR, aag$SRCVAR, aag$GRPTYPE, drop = TRUE))

  # Create AESI flags
  l_aesi <- lapply(l_aag, function(d_adag, d_adae) {
    names(d_adag)[names(d_adag) == "REFTERM"] <- d_adag$SRCVAR[1]
    names(d_adag)[names(d_adag) == "REFNAME"] <- d_adag$NAMVAR[1]

    if (d_adag$GRPTYPE[1] == "CUSTOM") {
      d_adag <- d_adag[-which(names(d_adag) == "SCOPE")]
    } else if (d_adag$GRPTYPE[1] == "SMQ") {
      names(d_adag)[names(d_adag) == "SCOPE"] <- paste0(substr(d_adag$NAMVAR[1], 1, 5), "SC")
    }

    d_adag <- d_adag[-which(names(d_adag) %in% c("NAMVAR", "SRCVAR", "GRPTYPE"))]
    d_new <- dplyr::left_join(x = d_adae, y = d_adag, by = intersect(names(d_adae), names(d_adag)))
    d_new[, dplyr::setdiff(names(d_new), names(d_adae)), drop = FALSE]
  }, adae)

  adae <- dplyr::bind_cols(adae, l_aesi)

  adae <- dplyr::mutate(adae, AERELNST = sample(
    x = c("CONCURRENT ILLNESS", "OTHER", "DISEASE UNDER STUDY", "NONE"),
    prob = c(0.3, 0.3, 0.3, 0.1),
    size = dplyr::n(),
    replace = TRUE
  ))


  adae <- adae %>%
    dplyr::mutate(AES_FLAG = sample(
      x = c("AESLIFE", "AESHOSP", "AESDISAB", "AESCONG", "AESMIE"),
      prob = c(0.1, 0.2, 0.2, 0.2, 0.3),
      size = dplyr::n(),
      replace = TRUE
    )) %>%
    dplyr::mutate(AES_FLAG = dplyr::case_when(
      AESDTH == "Y" ~ "AESDTH",
      TRUE ~ AES_FLAG
    )) %>%
    dplyr::mutate(
      AESCONG = ifelse(AES_FLAG == "AESCONG", "Y", "N"),
      AESDISAB = ifelse(AES_FLAG == "AESDISAB", "Y", "N"),
      AESHOSP = ifelse(AES_FLAG == "AESHOSP", "Y", "N"),
      AESLIFE = ifelse(AES_FLAG == "AESLIFE", "Y", "N"),
      AESMIE = ifelse(AES_FLAG == "AESMIE", "Y", "N")
    ) %>%
    dplyr::select(-"AES_FLAG")

  if (length(na_vars) > 0 && na_percentage > 0) {
    adae <- mutate_na(ds = adae, na_vars = na_vars, na_percentage = na_percentage)
  }

  # apply metadata
  adae <- apply_metadata(adae, "metadata/ADAE.yml")

  return(adae)
}
