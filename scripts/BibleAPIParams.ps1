Optional Parameters
Name: include-passage-references
Type: boolean
Default: true
Include the passage reference before the text.

Name: include-verse-numbers
Type: boolean
Default: true
Include verse numbers.

Name: include-first-verse-numbers
Type: boolean
Default: true
Include the verse number for the first verse of a chapter.

Name: include-footnotes
Type: boolean
Default: true
Include callouts to footnotes in the text.

Name: include-footnote-body
Type: boolean
Default: true
Include footnote bodies below the text. Only works if include-footnotes is also true.

Name: include-headings
Type: boolean
Default: true
Include section headings. For example, the section heading of Matthew 5 is 'The Sermon on the Mount'.

Name: include-short-copyright
Type: boolean
Default: true
Include '(ESV)' at the end of the text. Mutually exclusive with include-copyright. This fulfills your copyright display requirements.

Name: include-copyright
Type: boolean
Default: false
Include a copyright notice at the end of the text. Mutually exclusive with include-short-copyright. This fulfills your copyright display requirements.

Name: include-passage-horizontal-lines
Type: boolean
Default: false
Include a line of equal signs (====) above the beginning of each passage.

Name: include-heading-horizontal-lines
Type: boolean
Default: false
Include a visual line of underscores (____) above each section heading.

Name: horizontal-line-length
Type: integer
Default: 55
Controls the length of the line for include-passage-horizontal-lines and include-heading-horizontal-lines.

Name: include-selahs
Type: boolean
Default: true
Include 'Selah' in certain Psalms.

Name: indent-using
Type: string
Default: space
Controls indentation. Must be space or tab.

Name: indent-paragraphs
Type: integer
Default: 2
Controls how many indentation characters start a paragraph.

Name: indent-poetry
Type: boolean
Default: true
Controls indentation of poetry lines.

Name: indent-poetry-lines
Type: integer
Default: 4
Controls how many indentation characters are used per indentation level for poetry lines.

Name: indent-declares
Type: integer
Default: 40
Controls how many indentation characters are used for 'Declares the LORD' in some of the prophets.

Name: indent-psalm-doxology
Type: integer
Default: 30
Controls how many indentation characters are used for Psalm doxologies.

Name: line-length
Type: integer
Default: 0
Controls how long a line can be before it is wrapped. Use 0 for unlimited line lengths.