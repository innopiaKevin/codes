#!/bin/bash
ACCESS_TOKEN="access"

TVTS_PATH="/home/innopia/xts/arm_android-tvts-2.10_r1/android-tvts/results/latest"

# select test 
SELECT_TEST()
{
    echo "" 
    echo "   1. cts"
    echo "   2. tvts"
    echo "   3. vts"
    echo "   4. cts on gsi"
    echo "   5. gts"
    echo "   6. cts-v"
    echo "   7. sts"
    echo "   8. bts"
    echo "   9. export"
    echo "" 

    printf "choice test : "
    read TEST_TYPE
        echo "" 
        echo "TEST_TYPE=$TEST_TYPE"
        echo "" 

    case $TEST_TYPE in 
        1 ) CTS;;
        2 ) TVTS;;
        3 ) VTS;;
        4 ) CTS_ON_GSI;;
        5 ) GTS;;
        6 ) CTS_V;;
        7 ) STS;;
        8 ) BTS;;
        9 ) EXPORT_TVTS;;
        * ) echo "Invalid test!"; return;;
    esac
}
 
# open test_result_failures_suite.html
TVTS()
{
    HTML_FILE="$TVTS_PATH/test_result_failures_suite.html"
    # using xmllint parsing text
    INFO_TEST1=$(xmllint --html --xpath '/html/body/div/table/tr/td[@class="rowtitle"]/text()' "$HTML_FILE" 2>/dev/null)
    INFO_TEST2=$(xmllint --html --xpath '/html/body/div/table[@class="summary"]/tr/td[2]/text()' "$HTML_FILE" 2>/dev/null)
    FAIL_TEST=$(xmllint --html --xpath '/html/body/div/table/tr[td[@class="failed"]]/td[@class="testname"]/text()' "$HTML_FILE" 2>/dev/null)
    INCOMPLETE_TEST=$(xmllint --html --xpath '/html/body/div/table[@class="incompletemodules"]/tr/td/a/text()' "$HTML_FILE" 2>/dev/null)

    echo "TEST INFO" >> tvts-result.csv
    echo $INFO_TEST1 >> tvts-result.csv
    echo $INFO_TEST2 >> tvts-result.csv

    echo "FAIL TEST"
    echo $FAIL_TEST
    echo "IMCOMPLETE TEST"
    echo $INCOMPLETE_TEST

    # xmllint result to array  plus \n 
    IFS=$'/' read -d '' -r -a info1_array <<< "$INFO_TEST1"
    IFS=$'/' read -d '' -r -a info2_array <<< "$INFO_TEST2"
    IFS=$'\n' read -d '' -r -a fail_array <<< "$FAIL_TEST"
    IFS=$'\n' read -d '' -r -a incomplete_array <<< "$INCOMPLETE_TEST"

    echo "FAIL TEST" >> tvts-result.csv

    for ((i=0; i<${#info1_array[@]}; i++)); do
        info1_value="${info1_array[i]}"
        echo "$info1_value" >> tvts-result.csv
    done

    for ((i=0; i<${#info2_array[@]}; i++)); do
        info2_value="${info2_array[i]}"
        echo "$info2_value" >> tvts-result.csv
    done
    # fail test array to csv file add
    for ((i=0; i<${#fail_array[@]}; i++)); do
        fail_value="${fail_array[i]}"
        echo "$fail_value,fail" >> tvts-result.csv
    done

    echo "INCOMPLETE TEST" >> tvts-result.csv

    # incomplete test array to csv file add
    for ((i=0; i<${#incomplete_array[@]}; i++)); do
        incomplete_value="${incomplete_array[i]}"
        echo "$incomplete_value,incomplete" >> tvts-result.csv
    done

    # checking [] 
    # if echo "$fail_value" | grep -q '\[' && echo "$fail_value" | grep -q '\]'; then
    #     extracted_value=$(echo "$fail_value" | grep -oP '\[\K[^\]]+')
    #     echo "\"$extracted_value\"" >> tvts-result.csv
    # else
    #     echo "\"$fail_value\"" >> tvts-result.csv
    # fi
}

function GET_ACCESS_TOKEN 
{
    TOKEN_URL="https://oauth2.googleapis.com/token"
    CLIENT_ID="1099065693564-hc0afilo08qvlahmv8uj2plisv2dqs60.apps.googleusercontent.com"
    CLIENT_SECRET="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"
    REFRESH_TOKEN="1//0e7MKOUjrQJS4CgYIARAAGA4SNwF-L9IrWmpbCoTFPPMmHyCgLLyxwDtl9w4L1HSMy5EsDhLFfgqtm_P2MAVtyddn8CVWVzT2RHY"
    RESPONSE=$(curl -X POST $TOKEN_URL \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "refresh_token=$REFRESH_TOKEN" \
        -d "grant_type=refresh_token")

    sleep 3

    ACCESS_TOKEN=$(echo $RESPONSE | jq -r .access_token)

    echo "access token = $ACCESS_TOKEN"
}

function EXPORT_TVTS
{
    GET_ACCESS_TOKEN

    # CSV_FILE="/home/innopia/xts/commands/tvts-result.csv"
    # https://docs.google.com/spreadsheets/d/16VmjezbtMBtEXZOkyDfT16OQwfhNXSDYrUiFXoUy1vY/edit?gid=645133527#gid=645133527  
    # in above url, ID = 16VmjezbtMBtEXZOkyDfT16OQwfhNXSDYrUiFXoUy1vY
    SPREADSHEET_ID="1yhZLrRuU9o5GI2wV5_QkD9inA7XsnZ4OpoMQKFHmp6A"
    RANGE="DT_TVTS!D8"  # Update the sheet name accordingly
    echo "IN EXPORT TVTS ... access token = $ACCESS_TOKEN"
    # Prepare the data for the API request

    CSV_FILE="tvts-result.csv"

    # Ensure the CSV content is valid
    cat "$CSV_FILE"

    # Create JSON data
    JSON_DATA=$(jq -R -s 'split("\n") | map(select(length > 0) | split(",")) | {values: .}' "$CSV_FILE")

    sleep 3

    # Output JSON_DATA to verify
    echo "$JSON_DATA"
    
    # Make the API call
    RESPONSE=$(curl -s -w "%{http_code}" -o response.json -X POST "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values/$RANGE:append?valueInputOption=RAW" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$JSON_DATA")

    echo "Response Code: $RESPONSE"
    cat response.json

    if [ "$RESPONSE" -ne 200 ]; then
        echo "Failed to export data to Google Sheets."
    else
        echo "Data exported successfully."
    fi
}

function EXPORT_CTS_ON_GSI
{
    GET_ACCESS_TOKEN

    SPREADSHEET_ID=""
    RANGE=""

}


SELECT_TEST


