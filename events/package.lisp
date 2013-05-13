(cl:defpackage #:music-data
  (:use #:common-lisp)
  (:nicknames md)
  (:export ;; From events.lisp
   "DATASET-IDENTIFIER" "COMPOSITION-IDENTIFIER" "EVENT-IDENTIFIER"
	   "GET-DATASET-INDEX" "GET-COMPOSITION-INDEX" "GET-EVENT-INDEX"
	   "COPY-IDENTIFIER"
	   "LOOKUP-DATASET" "LOOKUP-COMPOSITION" "LOOKUP-EVENT"
	   "GET-DATASET" "GET-COMPOSITIONS" "GET-COMPOSITION"
	   "GET-EVENT-SEQUENCE" "GET-EVENT-SEQUENCES"
	   "COUNT-COMPOSITIONS" "COUNT-EVENTS"
	   "MUSIC-DATASET" "MUSIC-COMPOSITION" "MUSIC-EVENT" 
	   "IDENT" "ONSET" "CHROMATIC-PITCH" "DURATION" "KEY-SIGNATURE" "MODE"
	   "TEMPO" "PULSES" "BARLENGTH" "DELTAST" "BIOI" "PHRASE"
	   "MORPHETIC-PITCH" "ACCIDENTAL" "DYNAMICS" "ORNAMENT" "VOICE"
	   "COMMA" "ARTICULATION" "DESCRIPTION" "COMPOSITION-TIMEBASE"
	   "DATASET-TIMEBASE" "DATASET-MIDC"
	   "MUSIC-SYMBOL" "GET-ATTRIBUTE" "SET-ATTRIBUTE"
	   "*MD-MUSIC-SLOTS*" "*MD-TIME-SLOTS*"
           "GET-ALPHABET" "COPY-EVENT" "COMPOSITION->MONODY"
	   "CROTCHET" "TIMEBASE")
  (:documentation "Musical data."))

(cl:defpackage #:mtp-data
  (:use #:common-lisp)
  (:export "MTP-DATASET-IDENTIFIER" "MTP-COMPOSITION-IDENTIFIER"
	   "MTP-EVENT-IDENTIFIER" "MAKE-DATASET-ID" "MAKE-COMPOSITION-ID"
	   "MAKE-EVENT-ID" "DATASET-INDEX" "COMPOSITION-INDEX" "EVENT-INDEX"
	   "DB-EVENT->MTP-EVENT"
  ))