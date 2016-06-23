#!/usr/bin/env bats
# Tests for `deepdive sql` command

. "$BATS_TEST_DIRNAME"/env.sh >&2
PATH="$DEEPDIVE_SOURCE_ROOT/util/build/test:$PATH"

setup() {
    db-execute "SELECT 1" &>/dev/null || db-init
}

@test "$DBVARIANT deepdive sql works" {
    result=$(deepdive sql "
        CREATE TEMP TABLE foo(a INT);
        INSERT INTO foo VALUES (1), (2), (3), (4);
        COPY(SELECT SUM(a) AS sum FROM foo) TO STDOUT
        " | tee /dev/stderr | tail -1)
    [[ $result = 10 ]]
}

@test "$DBVARIANT deepdive sql eval works" {
    [[ $(deepdive sql eval "SELECT 1") = 1 ]]
}

@test "$DBVARIANT deepdive sql fails on bad SQL" {
    ! deepdive sql "
        CREATE;
        INSERT;
        SELECT 1
        " || false
}

@test "$DBVARIANT deepdive sql stops on error" {
    ! deepdive sql "
        CREATE TEMP TABLE foo(id INT);
        INSERT INTO foo SELECT id FROM __non_existent_table__$$;
        SELECT 1
        " || false
}

@test "$DBVARIANT deepdive sql eval fails on empty SQL" {
    ! deepdive sql eval "" || false
}

@test "$DBVARIANT deepdive sql eval fails on bad SQL" {
    ! deepdive sql eval "SELECT FROM WHERE" || false
}

@test "$DBVARIANT deepdive sql eval fails on non-SELECT SQL" {
    ! deepdive sql eval "CREATE TEMP TABLE foo(id INT)" || false
}

@test "$DBVARIANT deepdive sql eval fails on multiple SQL" {
    ! deepdive sql eval "CREATE TEMP TABLE foo(id INT); SELECT 1" || false
}

@test "$DBVARIANT deepdive sql eval fails on trailing semicolon" {
    ! deepdive sql eval "SELECT 1;" || false
}


load ../../database/test/corner_cases

###############################################################################
## a nasty SQL input to test output formatters

@test "$DBVARIANT deepdive sql eval format=tsv works" {
    actual=$(deepdive sql eval "$NastySQL" format=tsv)
    diff -u <(echo "$NastyTSV")                         <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval format=tsv header=1 works" {
    actual=$(deepdive sql eval "$NastySQL" format=tsv header=1)
    diff -u <(echo "$NastyTSVHeader"; echo "$NastyTSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval format=csv works" {
    actual=$(deepdive sql eval "$NastySQL" format=csv)
    diff -u <(echo "$NastyCSV")                         <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval format=csv header=1 works" {
    actual=$(deepdive sql eval "$NastySQL" format=csv header=1)
    diff -u <(echo "$NastyCSVHeader"; echo "$NastyCSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval format=json works" {
    actual=$(deepdive sql eval "$NastySQL" format=json)
    compare_json "$NastyJSON" "$actual"
}

@test "$DBVARIANT deepdive sql eval format=json works" {
    jq 'values' <<<"$NastyJSON"
    actual=$(deepdive sql eval "$NastySQL" format=json)
    compare_json "$NastyJSON" "$actual"
}


###############################################################################
## a case where NULL is in an array

@test "$DBVARIANT deepdive sql eval (with null in arrays) format=tsv works" {
    actual=$(deepdive sql eval "$NullInArraySQL" format=tsv)
    diff -u                               <(echo "$NullInArrayTSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with null in arrays) format=tsv header=1 works" {
    actual=$(deepdive sql eval "$NullInArraySQL" format=tsv header=1)
    diff -u <(echo "$NullInArrayTSVHeader"; echo "$NullInArrayTSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with null in arrays) format=csv works" {
    actual=$(deepdive sql eval "$NullInArraySQL" format=csv)
    diff -u                               <(echo "$NullInArrayCSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with null in arrays) format=csv header=1 works" {
    actual=$(deepdive sql eval "$NullInArraySQL" format=csv header=1)
    diff -u <(echo "$NullInArrayCSVHeader"; echo "$NullInArrayCSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with null in arrays) format=json works" {
    actual=$(deepdive sql eval "$NullInArraySQL" format=json)
    compare_json "$NullInArrayJSON" "$actual"   || skip # XXX not supported by pgtsv_to_json
}


###############################################################################
## a case with nested array

@test "$DBVARIANT deepdive sql eval (with nested arrays) format=tsv works" {
    actual=$(deepdive sql eval "$NestedArraySQL" format=tsv)
    diff -u                               <(echo "$NestedArrayTSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with nested arrays) format=tsv header=1 works" {
    skip  # XXX psql does not support HEADER for FORMAT text
    actual=$(deepdive sql eval "$NestedArraySQL" format=tsv header=1)
    diff -u <(echo "$NestedArrayTSVHeader"; echo "$NestedArrayTSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with nested arrays) format=csv works" {
    actual=$(deepdive sql eval "$NestedArraySQL" format=csv)
    diff -u                               <(echo "$NestedArrayCSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with nested arrays) format=csv header=1 works" {
    actual=$(deepdive sql eval "$NestedArraySQL" format=csv header=1)
    diff -u <(echo "$NestedArrayCSVHeader"; echo "$NestedArrayCSV") <(echo "$actual")
}

@test "$DBVARIANT deepdive sql eval (with nested arrays) format=json works" {
    actual=$(deepdive sql eval "$NestedArraySQL" format=json)   || skip # XXX not supported by driver.postgresql/db-query
    compare_json "$NestedArrayJSON" "$actual"
}
