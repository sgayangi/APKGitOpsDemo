import ballerina/http;
import ballerina/os;

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # A resource for generating greetings
    # + name - the input string name
    # + return - string name with hello message or error
    resource function get greeting(string name) returns http:Response {
        string environment = os:getEnv("ENVIRONMENT");
        json customerInfo = {};

        if environment == "dev" {
            // Dev environment - Use mock customer names and emails
            customerInfo = [
                {"name": "Test Customer 1", "email": "test1@example.com"},
                {"name": "Test Customer 2", "email": "test2@example.com"},
                {"name": "Test Customer 3", "email": "test3@example.com"}
            ];
        } else if environment == "staging" {
            // Staging environment - Use more realistic customer information with phone numbers
            customerInfo = [
                {"name": "Alice Johnson", "phone": "123-456-7890"},
                {"name": "Bob Smith", "phone": "098-765-4321"},
                {"name": "Charlie Davis", "phone": "555-555-5555"}
            ];
        }

        string message = "Hello, " + name + "! Here are the customers from the " + environment + " environment: ";
        http:Response response = new;
        response.setJsonPayload({"message": message, "customers": customerInfo});
        return response;
    }
}
