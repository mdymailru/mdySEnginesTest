//
//  ContentView.swift
//  mdySEnginesTest
//
//  Created by Dmitry Martynov on 21.10.2023.
//

import SwiftUI

let FitImage = "FitImage"

struct ContentView: View {
  
  @State private var image: UIImage? //= UIImage(named: "previewImage")
  @State private var isPickerPresent = false
  @State private var location: CGSize = .zero
  @State private var imgFitSize: CGSize = .zero
  
  private var imgSize: CGSize { image?.size ?? .zero }
  private var imgRatio: Double { imgSize.height / imgSize.width }
  
  private var xRatio: CGFloat { imgSize.width / imgFitSize.width }
  private var yRatio: CGFloat { imgSize.height / imgFitSize.height }
  private var imgXf: CGFloat { ((imgFitSize.width / 2 + location.width) * xRatio).rounded() }
  private var imgYf: CGFloat { ((imgFitSize.height / 2 + location.height) * yRatio).rounded() }
  
  private var imgX: String {
    if imgXf >= 0, imgXf <= imgSize.width  {
      return String(format: "%.0f", abs(imgXf))
    } else {
      return "out"
    }
  }
  
  private var imgY: String {
    if imgYf >= 0, imgYf <= imgSize.height  {
      return String(format: "%.0f", abs(imgYf))
    } else {
      return "out"
    }
  }
  
  var body: some View {
    ZStack {
      
      if let image {
        
          GeometryReader { geo in
            
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .background(frameReader())
              .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
              .magnification(location: $location,
                             imgFitSize: self.imgFitSize,
                             imgScale: 5)//(imgSize.width / geo.size.width))
            
              .onAppear { //debug
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
                  print("geo size: \(geo.size)")
                  print("fitImg size: \(imgFitSize)")
                  print("img size: \(imgSize)")
                  print("scale: \(imgRatio) - \(image.scale)")
                }
              }
          }
          //.border(.green)
          .contentShape(Rectangle())
          .coordinateSpace(name: FitImage)
       
        HStack {
          
          Button("Выйти") {
            self.location = .zero
            self.image = nil
          }
          
          Spacer()
          
          VStack {
            Text("x: \(String(format:"%.2f", location.width))")
            Text("y: \(String(format:"%.2f", location.height))")
          }
          
          VStack {
            Text("x: \(imgX)")
            Text("y: \(imgY)")
          }
          
          Spacer()
          
          Button("Продолжить") {
            print("pixel \(imgX),\(imgY)")
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
            UIPasteboard.general.string = "\(imgX),\(imgY)"
          }
          .disabled(imgX == "out" || imgY == "out")
        
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 10)
  
      } else {
      
        Button(
          action: { self.isPickerPresent = true },
          label: {
            Label("Сделать фото", systemImage: "camera")
              .frame(maxWidth: .infinity, maxHeight: 50)
              .background(Color.blue)
              .foregroundColor(.white)
              .cornerRadius(20)
              .padding(.horizontal)
        })
        
      }
    }
    .fullScreenCover(isPresented: $isPickerPresent) {
      
      ImagePickerView(selectedImage: self.$image)
        .edgesIgnoringSafeArea(.all)
    }.preferredColorScheme(.light)
  }
  
  private func frameReader() -> some View {
      return GeometryReader { (geo) -> Color in
          let imageSize = geo.size
          DispatchQueue.main.async {
              self.imgFitSize = imageSize
          }
          return .clear
      }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView()
    }
}


extension View {
  @ViewBuilder
  func magnification(location: Binding<CGSize>,
                     imgFitSize: CGSize,
                     imgScale: CGFloat) -> some View {
    
    MagnificationHelper(location: location,
                        imgFitSize: imgFitSize,
                        imgScale: imgScale) {
      self
    }
  }
}

fileprivate struct MagnificationHelper<Content: View>: View {
 
  var content: Content
  var offset: Binding<CGSize>
  @State var lastOffset: CGSize = .zero
  
  let imgFitSize: CGSize
  let imgScale: CGFloat
  
  init(location: Binding<CGSize>,
       imgFitSize: CGSize,
       imgScale: CGFloat,
       @ViewBuilder content: @escaping ()->Content) {
    
    self.content = content()
    self.offset = location
    self.imgFitSize = imgFitSize
    self.imgScale = trunc(imgScale).rounded()
  }
  
  var body: some View {
    
    content
      .reverseMask(content: {
        Circle()
          .frame(width: 150, height: 150)
          .offset(offset.wrappedValue)
      })
      .overlay {
        GeometryReader { geo in
          
          content
            .offset(x: -offset.wrappedValue.width, y: -offset.wrappedValue.height)
            .frame(width: geo.size.width, height: geo.size.height)
            .frame(width: 150, height: 150)
            .scaleEffect(imgScale)
            .clipShape(Circle())
            .offset(offset.wrappedValue)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
          
          Circle()
            .stroke()
            .fill(.red)
            
            .frame(width: 150, height: 150)
            .overlay {
              Rectangle()
                .frame(width: 1, height: 150, alignment: .center)
              .foregroundColor(.red)
            }
            .overlay {
              Rectangle()
                .frame(width: 150, height: 1, alignment: .center)
                .foregroundColor(.red)
            }
            .offset(offset.wrappedValue)
            .frame(width: geo.size.width, height: geo.size.height)
          
        }
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(coordinateSpace: .named(FitImage))
          .onChanged({ value in
            
            let dY = value.translation.height + lastOffset.height
            let dX = value.translation.width + lastOffset.width
            
            offset.wrappedValue = CGSize(width: dX, height: dY)
          })
          .onEnded({ _ in
            lastOffset = offset.wrappedValue
          })
      )
  }
  
}

extension View {
  func reverseMask<Content: View>(@ViewBuilder content: @escaping ()->Content) -> some View {
    self
      .mask {
        Rectangle()
          .overlay {
            content().blendMode(.destinationOut)
          }
      }
  }
  
}


