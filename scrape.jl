using Requests
import Requests: get

using JSON

clientid = "da6d5e5415582a69b4dc18c5f8d58e2e"
baseapi = "http://api.soundcloud.com"

# Get Soundcloud user id given user url
function resolveuser(url::AbstractString)
    req = Requests.get(
        joinpath(baseapi,"resolve?"),
        query = Dict("client_id" => clientid,"url" => url)
    )
    res = Requests.json(req)
    userid = res["id"]
    println(userid)
    return userid
end

# Recursively call through Soundcloud API linked partition data
function getlinkedpartition(res::Dict, collection::Array)
#    println(length(collection))
    if haskey(res,"collection")
        nextcollection = res["collection"]
    else
        return collection
    end
#    println(nextcollection)
    if !isequal(length(nextcollection),0)
        push!(collection, nextcollection...)
    end
    # Check if it has href for more data
    if haskey(res, "next_href")
        print(".")
        next_href = res["next_href"]
        if isequal(next_href,nothing)
            # No more hrefs
            return collection
        else
            # Recursively get next partition of data
            req = Requests.get(next_href)
            res = Requests.json(req)
            return getlinkedpartition(res, collection)
        end
    else
        # Return if no data
        println("Total objects found: ", length(collection))
        return collection
    end
end

# Download artwork to jpg from track object
function downloadartwork(track::Dict, size::AbstractString)
    if !isequal(track["artwork_url"], Void())
        try
            highres = replace(track["artwork_url"], "large", size)
            artwork = Requests.get(highres)
#       Requests.save(artwork, "$(track["title"]).jpg")
            Requests.save(artwork, replace(track["artwork_url"], "https://i1.sndcdn.com/", ""))
        catch
        end
    end
end

# Recursively download each track in an array
function downloadtracks(tracks::Array)
  if !isempty(tracks)
    track = pop!(tracks)
#    downloadartwork(track, "large")
    artworkurl = track["artwork_url"]
    if !isequal(artworkurl, Void())
        try
 #           highres = replace(track["artwork_url"], "large", size)
            artwork = Requests.get(artworkurl)
#       Requests.save(artwork, "$(track["title"]).jpg")
            Requests.save(artwork, replace(artworkurl, "https://i1.sndcdn.com/", ""))
        catch
        end
    end
    downloadtracks(tracks)
  end
end


# SCRAPE FAVORITES
function scrapefavorites(userid::Integer=49699208)
#    println("\tConnecting to Soundcloud for favorites")
    req = Requests.get(
        joinpath(baseapi,"users",string(userid),"favorites"),
        query = Dict("client_id" => clientid, "linked_partitioning" => "1")
    )
    res = Requests.json(req)
    favorites = getlinkedpartition(res, [])
    cd(() -> downloadtracks(favorites), "favorites")
end

# SCRAPE PLAYLISTS
function scrapeplaylists(userid::Integer=49699208, format::Regex=r"\[[0-9]{2}\.[0-9]{2}\.[0-9]{2}\]")
    if isequal(userid, 49699208)
        println("phamartin")
        format = r"\[[0-9]{2}\.[0-9]{2}\.[0-9]{2}\]"
    end
    println("Connecting to Soundcloud for playlists")
    req = Requests.get(
        joinpath(baseapi,"users",string(userid),"playlists"),
        query = Dict("client_id" => clientid, "linked_partitioning" => "1")
    )
    res = Requests.json(req)
    playlists = getlinkedpartition(res, [])
    weeklyplaylists = filter(pl -> ismatch(format, pl["title"]), playlists)
    
    function downloadplaylists(allplaylists)
        for playlist in allplaylists[1:4]
            title = playlist["title"]
            playlisttracks = playlist["tracks"]
            @printf("\tDownloading %i images from %s\n", length(playlisttracks), title)
            downloadtracks(playlisttracks)
        end
    end
    
    cd(() -> downloadplaylists(weeklyplaylists) ,"playlists")
end

#scrapefavorites(49699208)
# scrapeplaylists()
#scrapefavorites(64089230)
function scrapefollowers(userid)
#     userid = 49699208 # me
#    userid = 69813820 # kate
#    userid = 268155857 # eva
#    userid = 22548023 # kim
#    userid = 11379965 # pigeonsandplanes
    req = Requests.get(
        joinpath(baseapi,"users",string(userid),"followings"),
        query = Dict("client_id" => clientid, "linked_partitioning" => "1")
    )
    res = Requests.json(req)
    following = getlinkedpartition(res,[])
    return following
end


# resolveuser("https://soundcloud.com/kateviloria")
followers = scrapefollowers(268155857)
for f in followers
    scrapefavorites(f["id"])
end
println("*************")
followers = scrapefollowers(22548023)
for f in followers
    scrapefavorites(f["id"])
end
println("*************")
followers = scrapefollowers(11379965)
for f in followers
    scrapefavorites(f["id"])
end
# get favorites for all users you follow and make collage