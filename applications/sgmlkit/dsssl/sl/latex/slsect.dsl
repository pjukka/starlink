<![ ignore [

Title:
  Starlink General DTD -- LaTeX stylesheet for document elements

Author:
  Norman Gray, Glasgow (NG)

History:
  19 April 1999 (initial version)

Copyright 1999, Particle Physics and Astronomy Research Council

$Id$
]]>

<func>
<routinename>$latex-section$
<description>Simple function which should be called for all sectioning
commands.
<returnvalue type=sosofo>Produces a sosofo which creates the section heading.
<parameter>section-cmd
  <type>string
  <description>LaTeX command to format the title
<parameter keyword default="#t">children
  <type>boolean
  <description>If true, then invoke <funcname/process-children/, too. 
  It would be necessary to switch this off if there is some reason why
  the element contents should <em/not/ be taken to be the section contents.
<codebody>
(define ($latex-section$ section-cmd #!key (children #t))
  (make sequence
    (make command name: section-cmd
	  (with-mode section-reference
	    (process-node-list (current-node))))
    (if children
	(process-children)
	(empty-sosofo))))

<misccode>
<description>
Section constructors

<codebody>
(element sect ($latex-section$ "section"))
(element subsect ($latex-section$ "subsection"))
(element subsubsect ($latex-section$ "subsubsection"))
(element subsubsubsect ($latex-section$ "paragraph"))
;(element appendices ($latex-section$ "section"))

;; Discard the subhead, except when we're in in-section-head mode
(element subhead
  (empty-sosofo))
(mode in-section-head
  (element subhead
    (process-children-trim)))

