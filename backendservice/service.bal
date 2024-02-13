import ballerina/http;
import ballerina/os;

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function get customers() returns http:Response {
        string environment = os:getEnv("ENVIRONMENT");
        json customerInfo = {};

        if environment == "dev" {
            customerInfo = [
                {"name": "Test Customer 1", "email": "test1@example.com"},
                {"name": "Test Customer 2", "email": "test2@example.com"},
                {"name": "Test Customer 3", "email": "test3@example.com"}
            ];
        } else if environment == "staging" {

            customerInfo = [
                {"name": "Alice Johnson", "email": "alice@mail.com"},
                {"name": "Bob Smith", "email": "bob@mail.com"},
                {"name": "Charlie Davis", "email": "charlie@mail.com"}
            ];
        }

        string message = "Here are the customers from the " + environment + " environment: ";
        http:Response response = new;
        response.setJsonPayload({"message": message, "customers": customerInfo});
        return response;
    }
}
