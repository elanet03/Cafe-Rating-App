import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

actor CafeRating {
    // Define the Rating structure
    public type Rating = {
        coffeeScore: Nat;
        comfortScore: Nat;
        serviceScore: Nat;
        crowdScore: Nat;
        comment: ?Text;
        rater: Text;
    };

    // Define the Cafe structure with immutable fields for sharing
    public type Cafe = {
        name: Text;
        location: Text;
        ratings: [Rating];
        averageRating: Nat;
    };

    // Initialize stable storage for cafes
    private stable var cafeEntries : [(Text, Cafe)] = [];
    private var cafes = HashMap.fromIter<Text, Cafe>(cafeEntries.vals(), 0, Text.equal, Text.hash);

    // Function to add a new cafe
    public func addCafe(name: Text, location: Text) : async Bool {
        switch (cafes.get(name)) {
            case (?_) { 
                false // Cafe already exists
            };
            case (null) {
                let newCafe : Cafe = {
                    name = name;
                    location = location;
                    ratings = [];
                    averageRating = 0;
                };
                cafes.put(name, newCafe);
                true
            };
        }
    };

    // Function to add a rating for a cafe
    public func addRating(cafeName: Text, rating: Rating) : async Bool {
        switch (cafes.get(cafeName)) {
            case (?cafe) {
                let newRatings = Array.append<Rating>(cafe.ratings, [rating]);
                
                // Calculate new average rating
                let totalRatings = newRatings.size();
                var sum = 0;
                for (r in newRatings.vals()) {
                    sum += r.coffeeScore + r.comfortScore + r.serviceScore + r.crowdScore;
                };
                let newAverage = sum / (totalRatings * 4);

                let updatedCafe : Cafe = {
                    name = cafe.name;
                    location = cafe.location;
                    ratings = newRatings;
                    averageRating = newAverage;
                };
                cafes.put(cafeName, updatedCafe);
                true
            };
            case (null) {
                false // Cafe doesn't exist
            };
        }
    };

    // Public type for sharing cafe details
    public type CafeView = {
        name: Text;
        location: Text;
        ratings: [Rating];
        averageRating: Nat;
    };

    // Function to get cafe details including all ratings
    public query func getCafeDetails(cafeName: Text) : async ?CafeView {
        switch (cafes.get(cafeName)) {
            case (?cafe) {
                ?{
                    name = cafe.name;
                    location = cafe.location;
                    ratings = cafe.ratings;
                    averageRating = cafe.averageRating;
                }
            };
            case (null) { null };
        }
    };

    // Function to get average ratings for a specific cafe
    public query func getCafeAverages(cafeName: Text) : async ?{
        avgCoffee: Nat;
        avgComfort: Nat;
        avgService: Nat;
        avgCrowd: Nat;
        totalRatings: Nat;
    } {
        switch (cafes.get(cafeName)) {
            case (?cafe) {
                if (cafe.ratings.size() == 0) {
                    return null;
                };
                
                var coffeeSum = 0;
                var comfortSum = 0;
                var serviceSum = 0;
                var crowdSum = 0;
                
                for (rating in cafe.ratings.vals()) {
                    coffeeSum += rating.coffeeScore;
                    comfortSum += rating.comfortScore;
                    serviceSum += rating.serviceScore;
                    crowdSum += rating.crowdScore;
                };

                let totalRatings = cafe.ratings.size();
                
                ?{
                    avgCoffee = coffeeSum / totalRatings;
                    avgComfort = comfortSum / totalRatings;
                    avgService = serviceSum / totalRatings;
                    avgCrowd = crowdSum / totalRatings;
                    totalRatings = totalRatings;
                }
            };
            case (null) { null };
        }
    };

    // Function to list all cafes with their average ratings
    public query func listAllCafes() : async [(Text, Nat)] {
        let cafesArray = Iter.toArray(cafes.entries());
        Array.map<(Text, Cafe), (Text, Nat)>(cafesArray, func(entry) {
            (entry.0, entry.1.averageRating)
        })
    };

    // Required for upgrades
    system func preupgrade() {
        cafeEntries := Iter.toArray(cafes.entries());
    };

    system func postupgrade() {
        cafeEntries := [];
    };
}
