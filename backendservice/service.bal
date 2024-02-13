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
        string message = "Hello, " + name + " from " + environment + " environment!";
        http:Response response = new;
        response.setTextPayload(message);
        return response;
    }
}
