import Foundation

// MARK: - Face Detection Response Models
/// These models represent the response structure for face detection results
/// including the detected faces, their attributes, and video metadata.

// MARK: FaceDetectionResponse
struct FaceDetectionResponse: Codable {
    let faces: [FaceWrapper]              // Array of face wrappers containing face details and timestamp
    let nextToken: String?                // Token for pagination if applicable
    let status: String?                   // Status message from the detection service
    let videoMetadata: VideoMetadata?     // Metadata of the video processed

    enum CodingKeys: String, CodingKey {
        case faces = "faces"
        case nextToken = "next_token"
        case status = "status"
        case videoMetadata = "video_metadata"
    }
}

// MARK: FaceWrapper
struct FaceWrapper: Codable {
    let face: Face                        // Detailed face information
    let timestamp: Int                    // Timestamp of the detection within the video

    enum CodingKeys: String, CodingKey {
        case face = "Face"
        case timestamp = "Timestamp"
    }
}

// MARK: Face
struct Face: Codable {
    let ageRange: AgeRange                // Age range of the detected face
    let beard: Attribute                  // Beard detection details
    let boundingBox: BoundingBox          // Coordinates of the face in the image
    let confidence: Double                // Overall detection confidence
    let emotions: [Emotion]               // List of detected emotions with confidence scores
    let eyeglasses: Attribute             // Eyeglasses attribute
    let eyesOpen: Attribute               // Eyes open attribute
    let gender: Gender                    // Gender detection details
    let landmarks: [Landmark]             // Facial landmarks
    let mouthOpen: Attribute              // Mouth open attribute
    let mustache: Attribute               // Mustache detection details
    let pose: Pose                        // Pose information (pitch, roll, yaw)
    let quality: Quality                  // Quality metrics (brightness, sharpness)
    let smile: Attribute                  // Smile attribute
    let sunglasses: Attribute             // Sunglasses attribute

    enum CodingKeys: String, CodingKey {
        case ageRange = "AgeRange"
        case beard = "Beard"
        case boundingBox = "BoundingBox"
        case confidence = "Confidence"
        case emotions = "Emotions"
        case eyeglasses = "Eyeglasses"
        case eyesOpen = "EyesOpen"
        case gender = "Gender"
        case landmarks = "Landmarks"
        case mouthOpen = "MouthOpen"
        case mustache = "Mustache"
        case pose = "Pose"
        case quality = "Quality"
        case smile = "Smile"
        case sunglasses = "Sunglasses"
    }
}

// MARK: AgeRange
struct AgeRange: Codable {
    let high: Int                         // Upper bound of the detected age range
    let low: Int                          // Lower bound of the detected age range

    enum CodingKeys: String, CodingKey {
        case high = "High"
        case low = "Low"
    }
}

// MARK: Attribute
struct Attribute: Codable {
    let confidence: Double                // Confidence score for the attribute
    let value: Bool                       // Boolean value indicating presence or absence

    enum CodingKeys: String, CodingKey {
        case confidence = "Confidence"
        case value = "Value"
    }
}

// MARK: BoundingBox
struct BoundingBox: Codable {
    let height: Double                    // Height of the bounding box
    let left: Double                      // Left coordinate of the bounding box
    let top: Double                       // Top coordinate of the bounding box
    let width: Double                     // Width of the bounding box

    enum CodingKeys: String, CodingKey {
        case height = "Height"
        case left = "Left"
        case top = "Top"
        case width = "Width"
    }
}

// MARK: Emotion
struct Emotion: Codable {
    let confidence: Double                // Confidence score for the emotion
    let type: String                      // Type of emotion (e.g., HAPPY, SAD)

    enum CodingKeys: String, CodingKey {
        case confidence = "Confidence"
        case type = "Type"
    }
}

// MARK: Gender
struct Gender: Codable {
    let confidence: Double                // Confidence score for gender detection
    let value: String                     // Gender value (e.g., Male, Female)

    enum CodingKeys: String, CodingKey {
        case confidence = "Confidence"
        case value = "Value"
    }
}

// MARK: Landmark
struct Landmark: Codable {
    let type: String                      // Type of landmark (e.g., eye, nose)
    let x: Double                         // X-coordinate of the landmark
    let y: Double                         // Y-coordinate of the landmark

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case x = "X"
        case y = "Y"
    }
}

// MARK: Pose
struct Pose: Codable {
    let pitch: Double                     // Pitch angle
    let roll: Double                      // Roll angle
    let yaw: Double                       // Yaw angle

    enum CodingKeys: String, CodingKey {
        case pitch = "Pitch"
        case roll = "Roll"
        case yaw = "Yaw"
    }
}

// MARK: Quality
struct Quality: Codable {
    let brightness: Double                // Brightness metric
    let sharpness: Double                 // Sharpness metric

    enum CodingKeys: String, CodingKey {
        case brightness = "Brightness"
        case sharpness = "Sharpness"
    }
}

// MARK: VideoMetadata
struct VideoMetadata: Codable {
    let codec: String                     // Codec used for the video
    let colorRange: String                // Color range information
    let durationMillis: Int               // Duration of the video in milliseconds
    let format: String                    // Video format
    let frameHeight: Int                  // Height of the video frame
    let frameRate: Double                 // Frame rate of the video
    let frameWidth: Int                   // Width of the video frame

    enum CodingKeys: String, CodingKey {
        case codec = "Codec"
        case colorRange = "ColorRange"
        case durationMillis = "DurationMillis"
        case format = "Format"
        case frameHeight = "FrameHeight"
        case frameRate = "FrameRate"
        case frameWidth = "FrameWidth"
    }
}
