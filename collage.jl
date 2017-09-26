using Images
using FileIO

# Generate hilbert vertices recursively
function hilbert2d(n::Int)
    if n == 0
        x = 0
        y = 0
    else
        x0,y0 = hilbert2d(n-1)
        x = .5*[-.5+y0 -.5+x0 .5+x0 .5-y0]
        y = .5*[-.5+x0 .5+y0 .5+y0 -.5-x0]
    end
    x,y
end

# n: resolution level
# curve: Julia function to return vertices of space filling curve
# returns values [-0.5,0.5]^2 into indices (for 1-indexed square images)
function indices2dcurve(n,curve)
    x,y = curve(n)
    xi = (2^n)*(x+0.5) + 0.5
    yi = (2^n)*(y+0.5) + 0.5
    c = map(x -> round(Int,x), xi)
#     r = map(y -> (2^n+1)-round(Int,y), yi) #row column downwards so inverse by length
    r = map(y -> round(Int,y), yi) # regular non-image indices
    c,r
end

# x2,y2 = hilbert2d(3)
#x2,y2 = indices2dcurve(12,hilbert2d)
#println(x2)
#println(y2)
#println(max(x2...))

# Construct 4096x4096 image of all colours using Hilbert curve
function allcolourimage(curve,colourer)
    x,y = indicescurve(12,curve)
    colourgen = Task(colourer)
    v0 = colorview(RGB, zeros(N0f8,3,4096,4096))
    for i = 1:length(x)
        v0[y[i],x[i]] = consume(colourgen)
    end
    v0
end

rotx(t) = [[1 0 0];
           [0 cos(t) -sin(t)];
           [0 sin(t) cos(t)]]
roty(t) = [[cos(t) 0 sin(t)];
           [0 1 0];
           [-sin(t) 0 cos(t)]]
rotz(t) = [[cos(t) -sin(t) 0];
           [sin(t) cos(t) 0];
           [0 0 1]]

# R rotation matrix
# x,y,z same length
function rotatecurve(x,y,z,R)
    x0 = copy(x) # make copies because Julia assigns by reference
    y0 = copy(y)
    z0 = copy(z)
    for i = 1:length(x)
        x0[i],y0[i],z0[i] = R*[x0[i];y0[i];z0[i]]
    end
    x0,y0,z0
end

t1(x,y,z) = begin
    R = rotz(-.5pi)*roty(-.5pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x - .5)
    y = .5*(y - .5)
    z = .5*(z - .5)
    x,y,z
end
t2(x,y,z) = begin
    R = roty(.5pi)*rotz(.5pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x - .5)
    y = .5*(y - .5)
    z = .5*(z + .5)
    x,y,z
end
t3(x,y,z) = begin
    R = roty(.5pi)*rotz(.5pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x - .5)
    y = .5*(y + .5)
    z = .5*(z + .5)
    x,y,z
end
t4(x,y,z) = begin
    R = rotx(pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x - .5)
    y = .5*(y + .5)
    z = .5*(z - .5)
    x,y,z
end
t5(x,y,z) = begin
    R = rotx(pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x + .5)
    y = .5*(y + .5)
    z = .5*(z - .5)
    x,y,z
end
t6(x,y,z) = begin
    R = roty(-.5pi)*rotz(-.5pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x + .5)
    y = .5*(y + .5)
    z = .5*(z + .5)
    x,y,z
end
t7(x,y,z) = begin
    R = roty(-.5pi)*rotz(-.5pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x + .5)
    y = .5*(y - .5)
    z = .5*(z + .5)
    x,y,z
end
t8(x,y,z) = begin
    R = rotx(-.5pi)*rotz(.5pi)
    x,y,z = rotatecurve(x,y,z,R)
    x = .5*(x + .5)
    y = .5*(y - .5)
    z = .5*(z - .5)
    x,y,z
end

function hilbert3d(n::Int)
    if n <= 0
        x = [0]
        y = [0]
        z = [0]
    else
        c = hilbert3d(n-1)
        x1,y1,z1 = t1(c...)
        x2,y2,z2 = t2(c...)
        x3,y3,z3 = t3(c...)
        x4,y4,z4 = t4(c...)
        x5,y5,z5 = t5(c...)
        x6,y6,z6 = t6(c...)
        x7,y7,z7 = t7(c...)
        x8,y8,z8 = t8(c...)
        x = [x1..., x2..., x3..., x4..., x5..., x6..., x7..., x8...]
        y = [y1..., y2..., y3..., y4..., y5..., y6..., y7..., y8...]
        z = [z1..., z2..., z3..., z4..., z5..., z6..., z7..., z8...]
    end
    x,y,z
end

function indices3dcurve(n::Int,curve)
    x,y,z = curve(n)
    xi = (2^n)*(x+0.5) + 0.5
    yi = (2^n)*(y+0.5) + 0.5
    zi = (2^n)*(z+0.5) + 0.5
    c = map(x-> round(Int, x-1), xi)
    r = map(y-> round(Int, y-1), yi)
    p = map(z-> round(Int, z-1), zi)
    c,r,p
end

# x3,y3,z3 = indices3dcurve(8,hilbert3d)
#println(x3)
#println(y3)
#println(z3)
# println(max(x3...))

# Given an image array, determine its most popular position in RGB space
function characterizeimage(img)
  test = zeros(Int,256,256,256)
  if isequal(typeof(img), Array{ColorTypes.RGB4{FixedPointNumbers.Normed{UInt8,8}},2})
#    println("RGB")
    img = rawview(channelview(img))
    dims = size(img)
    # println(dims)
    for x = 1:dims[3]
      for y = 1:dims[2]
        # println("$(y) $(x)")
        r,g,b = img[:,y,x]
        test[r+1,g+1,b+1] = test[r+1,g+1,b+1]+1
      end
    end
  else
#    println("Gray")
    img = rawview(channelview(img))
    for p in img
      # println(p)
      test[p+1,p+1,p+1] = test[p+1,p+1,p+1]+1
    end
  end
  # Find index in RGB with most pixels of that colour
  bestrgb = (1,1,1)
  bestcount = 0
  for r = 1:256
    for g = 1:256
      for b = 1:256
        if bestcount < test[r,g,b]
          bestrgb = (r,g,b)
          bestcount = test[r,g,b]
        end
      end
    end
  end
  # println("$(bestrgb) $(bestcount) $(max(test...))")
  # println("$(mean(img[1,:,:])) $(mean(img[2,:,:])) $(mean(img[3,:,:]))")
  bestrgb
end

# Generate 2D and 3D Hilbert curves for sorting
#@printf("Generating 2D Hilbert curve\n")
# x2,y2 = indices2dcurve(3,hilbert2d)
@printf("Generating 3D Hilbert curve\n")
x3,y3,z3 = indices3dcurve(8,hilbert3d)

# Read image files and sort into a dict with keys "r g b" associated with array of image filenames
function sortimages(hcurve3dr,hcurve3dg,hcurve3db)
  # Read image files and sort
  files = readdir()
  rgbkey = rgb -> "$(rgb[1]) $(rgb[2]) $(rgb[3])"
  imagedict = Dict{String,Array}()
  for f in files
    img = load("$(f)")
    char = characterizeimage(img)
#    println(char, f)
    key = rgbkey(char)
    if haskey(imagedict,key)
      push!(imagedict[key], f)
    else
      imagedict[key] = [f]
    end
  end
  # Loop over RGB space to construct sorted list of files
  sortedfiles = []
  for rgb in collect(zip(hcurve3dr,hcurve3dg,hcurve3db))
    key = rgbkey(rgb)
    if haskey(imagedict,key)
#      println(rgb,imagedict[key])
      push!(sortedfiles, imagedict[key]...)
    end
  end
  return sortedfiles
end

cd("favorites")
sortedfiles = sortimages(x3,y3,z3)
#cd("..")
show(sortedfiles)

# Define Collage Type for filling image
type Collage
  xdim
  ydim
  tilewidth
  data
end
function addtile(collage::Collage,y::Int,x::Int,tile::Array)
  xstart = (x-1)*collage.tilewidth + 1
  xend = x*collage.tilewidth
  ystart = (y-1)*collage.tilewidth + 1
  yend = y*collage.tilewidth
  collage.data[ystart:yend,xstart:xend] = tile'
  return collage
end
function fillcollage(tiles::Array)
  x2, y2 = indices2dcurve(3,hilbert2d)
  collage = Collage(8,8,100, Array{ColorTypes.RGB4{FixedPointNumbers.Normed{UInt8,8}},2}(8*100,8*100))
  for xy in collect(zip(x2,y2))
    if (length(tiles)!=0)
      f = pop!(tiles)
      fimg = data(convert(Image{RGB}, load("$(f)")))
      collage = addtile(collage, xy[2], xy[1],fimg)
    end
  end
  output = Image(collage.data')
  Images.save("../testartworkcollage.jpg",output)
end

fillcollage(sortedfiles)
