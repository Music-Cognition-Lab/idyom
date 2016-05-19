(cl:defpackage #:music-data
  (:use #:common-lisp)
  (:nicknames md)
  (:export 
   ;; Music objects & their properties
   "MUSIC-DATASET" "MUSIC-COMPOSITION" "MUSIC-EVENT" "MUSIC-SLICE"
   "MUSIC-SEQUENCE" "MELODIC-SEQUENCE" "HARMONIC-SEQUENCE"
   "ONSET" "CHROMATIC-PITCH" "DURATION" "KEY-SIGNATURE" "MODE"
   "TEMPO" "PULSES" "BARLENGTH" "DELTAST" "BIOI" "PHRASE"
   "MORPHETIC-PITCH" "ACCIDENTAL" "DYNAMICS" "ORNAMENT" "VOICE"
   "COMMA" "ARTICULATION" "DESCRIPTION" "MIDC" "TIMEBASE" "VERTINT12"
   "RESOLUTION" "IS-ONSET" "POS" "GRID-SEQUENCE"
   "METRICAL-INTERPRETATION" "METER-PERIOD" "METER-PHASE"
   "METER-STRING" "METER-STRING->METRICAL-INTERPRETATION"
   "CATEGORY-STRING" "CREATE-INTERPRETATIONS"
   "MAKE-METRICAL-INTERPRETATION" "BEAT-DIVISION"
   ;; Identifiers
   "DATASET-IDENTIFIER" "COMPOSITION-IDENTIFIER" "EVENT-IDENTIFIER"
   "GET-DATASET-INDEX" "GET-COMPOSITION-INDEX" "GET-EVENT-INDEX"
   "MAKE-DATASET-ID" "MAKE-COMPOSITION-ID" "MAKE-EVENT-ID" 
   "COPY-IDENTIFIER" "GET-IDENTIFIER"
   "LOOKUP-DATASET" "LOOKUP-COMPOSITION" "LOOKUP-EVENT"
   ;; Getting music objects from DB
   "GET-DATASET" "GET-COMPOSITION" "GET-EVENT"
   "GET-MUSIC-OBJECTS" "GET-EVENT-SEQUENCE" "GET-EVENT-SEQUENCES"
   "GET-GRID-SEQUENCE" "GET-GRID-SEQUENCES"
   ;; Accessing properties of music objects
   "GET-ATTRIBUTE" "SET-ATTRIBUTE" "COUNT-COMPOSITIONS" "GET-DESCRIPTION"
   "COPY-EVENT" "MUSIC-SYMBOL" "*MD-MUSIC-SLOTS*" "*MD-TIME-SLOTS*"
   "HAS-TIME-SIGNATURE?" "SAME-TIME-SIGNATURE?" "PERIOD"
   "TIME-SIGNATURE->METRICAL-INTERPRETATION"
   ;; Representation
   "RESCALE")
)
  (:documentation "Musical data."))

