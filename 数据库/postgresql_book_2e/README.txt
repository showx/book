The .sql is a plain text SQL backup
that should be restored with psql.

It consists of the census and staging schemas. As well as some other minor tables
Some of these are built as part of exercises in the book.  

To restore:
CREATE DATABASE postgresql_book;
\connect postgresql_book
\i postgresql_book.sql