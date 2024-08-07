#!/bin/sh

if [ $# -ne 3 ]; then
  printf "\nUSAGE: $0 <person_id> <person_name> <api|jwt>"
  printf "\n A existing person with the given numeric person_id will be updated using the given person_name"
  printf "\n Please make sure a person exists with the given person_id"
  printf "\n One of either 'api' or 'jwt' should be provided as the third argument"
  printf "\n   If 'api' is provided then api_key header will be used to authenticate"
  printf "\n   and if 'jwt' is provided then bearer header will be used to authenticate"
  printf "\n Please make sure the id does not already belong to an existing person"
  printf "\nExiting!!!\n"
  exit -1
fi

counter=0

person_id=$1
person_updated_name="$2"
auth_method=$3
case $3 in
  api)
    header_auth="api_key: secret"
    ;;
  jwt)
    header_auth="Authorization: Bearer $ACCESS_TOKEN"
    ;;
  *)
    printf "\nNeither 'api' nor 'jwt' is provided as the third argument"
    printf "\n  third arg: [%s] <- INVALID VALUE" $3
    printf "\nExiting!!!\n"
    exit -1
esac

header_content_type="Content-Type: application/json"
body_json=$(printf '{"id": %s, "name": "%s"}' "$person_id" "$person_updated_name")
api_endpoint="https://$(oc get httproute kamel-rest -n ${KAMEL_NS} -o=jsonpath='{.spec.hostnames[0]}')/api/person"

printf "\nTesting the kamel route for PUT operation - with API key in the header - should get 200 or 500 response...\n"
until curl -XPUT -H "$header_auth" -H "$header_content_type" -s -k -o /dev/null -w "%{http_code}" "$api_endpoint" -d "$body_json" | grep -E "[245][0-9][0-9]"
do
  printf '.'
  sleep 1
  if [ $counter -gt 300 ]; then
    CURL_RESP=`curl -XPUT -H "$header_auth" -H "$header_content_type" -s -k -o /dev/null -w "%{http_code}" "$api_endpoint" -d "$body_json"`
    printf "\n\n -->> ERROR:: Curl command should have returned 200 response but we got %d instead <<--\n Exiting!!!\n\n" $CURL_RESP
    exit
  fi
  (( counter++ ))
done

printf "\n\n -->> Route tested successfully (for PUTT call) after %d seconds...\n" $counter
