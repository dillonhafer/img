import Foundation
import SwiftUI


extension NSImage {
  var PNGRepresentation: Data? {
    if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
      return tiffData.representation(using: .png, properties: [:])
    }
    return nil
  }
}

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}

func writeFile(data: Data) {
  let url = getDocumentsDirectory().appendingPathComponent("lastKnownImage")

  do {
    try data.write(to: url)
  } catch {
    print(error.localizedDescription)
  }
}

func readFile() -> NSImage? {
  let url = getDocumentsDirectory().appendingPathComponent("lastKnownImage")
  if let img = NSImage(contentsOf: url) {
    return img
  }

  print("Could not load data \(url.absoluteString)")
  return nil
}

extension NSOpenPanel {
  static func openImage(completion: @escaping (_ result: Result<NSImage, Error>) -> ()) {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [.jpeg, .png, .heic]
    panel.canChooseFiles = true
    panel.begin { (result) in
      if result == .OK,
         let url = panel.urls.first,
         let image = NSImage(contentsOf: url) {
        print("Writing \(panel.urls.first!.absoluteURL)")
        UserDefaults.standard.set(panel.urls.first!.absoluteURL, forKey: "lastImageUrl")
        completion(.success(image))
      } else {
        completion(.failure(
          NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get file location"])
        ))
      }
    }
  }
}

struct InputView: View {

  @Binding var image: NSImage?

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Text("Input Image (PNG,JPG,JPEG,HEIC)")
        Button(action: selectFile) {
          Text("From Finder")
        }
      }
      InputImageView(image: self.$image)
    }
  }

  private func selectFile() {
    NSOpenPanel.openImage { (result) in
      if case let .success(image) = result {
        self.image = image
      }
    }
  }
}


struct InputImageView: View {

  @Binding var image: NSImage?

  var body: some View {
    ZStack {
      if self.image != nil {
        Image(nsImage: self.image!)
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else {
        Text("Drag and drop image file")
          .frame(width: 320)
      }
    }
    .frame(height: 320)
    .background(Color.black.opacity(0.5))
    .cornerRadius(8)

    .onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
      if let item = items.first {
        if let identifier = item.registeredTypeIdentifiers.first {
          print("onDrop with identifier = \(identifier)")
          if identifier == "public.url" || identifier == "public.file-url" {
            item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
              DispatchQueue.main.async {
                if let urlData = urlData as? Data {
                  let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                  if let img = NSImage(contentsOf: urll) {
                    writeFile(data: img.PNGRepresentation!)
                    self.image = img
                  }
                }
              }
            }
          }
        }
        return true
      } else {
        return false
      }
    }
  }
}

struct ContentView: View {
  @State var image: NSImage? = nil
  @State private var dragOver = false

  var body: some View {
    InputImageView(image: $image).onAppear(perform: loadImage)
  }

  func loadImage() {
    if let img = readFile() {
      DispatchQueue.main.async {
        self.image = img
      }
    }
  }
}



