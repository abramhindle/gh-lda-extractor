import os
import nltk
#import couchdb
import json
import re
import math
#import pdb; 

#import scipy.spatial.distance
#import pyflann

#def connect_to_couchdb():
#    couch = couchdb.Server() #connects to localhost:5984(by default, we could change this), our couchdb server
#    db = couch['bugparty'] #creates an object from the bugparty db
#    return db

def get_ids(db):
    ids = db['_all_docs']
    ids = [x["id"] for x in ids["rows"] if x["id"][0] != "_" ]
    return ids

def d2s(v):
    if (v == {}):
        return ""
    return v

def blank( d ):
    if (d == None):
        return ''
    else:
        return d

def d2sblank(doc, key):
    return blank(d2s(doc.get(key,"")))

def as_list(v):
    if (v.__class__ == [].__class__):
        return v
    return [v]

def reverse_dict( dicts ):
    return dict((v,k) for k, v in dicts.iteritems())

_stopwords = False
def stopwords():
    global _stopwords
    if (_stopwords == False):
        try:
            _stopwords = set(open("stop_words").read().splitlines())
        except:
            _stopwords = {}
        _stopwords.add("")
        _stopwords.add("'s")
    return _stopwords

stopwordp = re.compile("^[a-zA-Z0-9\\._\\/\\\\]+$",re.I)
def filter_stopwords( tokens ):
    global stopwordp
    sw = stopwords()
    w1 = [x for x in tokens if not(x in sw)] 
    return [y for y in w1 if not(None == stopwordp.match(y))]

def tokenize( text ):
    tokens = filter_stopwords( nltk.word_tokenize( text.lower() ) )
    return tokens

def convert_doc_to_count( doc, dicts ):
    return convert_tokens_to_count( tokenize( doc ), dicts)

def convert_tokens_to_count( tokens, dicts ):
    counts = {}
    for token in tokens:
        id = dicts.get(token, -1)
        if ( id != -1):
            counts[id] = counts.get(id, 0) + 1
    return counts

def add_doc( doc, dicts, counter ):
    tokens = tokenize( doc )
    # count tokens and make dictionary from them
    counts = {}
    for token in tokens:
        if (dicts.get(token, -1) == -1):
            dicts[token] = counter
            counter += 1
        id = dicts[token]
        oldcount = counts.get(id, 0)
        counts[id] = oldcount + 1
    return (counter, counts)



def extract_text_from_document( doc ):
    doc_comments = as_list(doc.get("comments",[]))
    comments = "\n".join([ d2s(x["author"]) + " " + d2s(x.get("what","")) + d2s(x.get("content",""))  or '' for x in doc_comments])
    outdoc = "\n".join([
            d2sblank(doc,"owner"),
            d2sblank(doc,"reportedBy"),
            d2sblank(doc,"title"),
            d2sblank(doc,"description"),
            d2sblank(doc,"content"),
            blank(comments)
            ])
    return outdoc

def load_lda_docs(db, ids ):
    dicts  = {"_EMPTY_":1}
    counter = 2
    docs = {}
    for id in ids:
        print(id)
        doc = db[id]
        #if (id == 180):
        #    pdb.set_trace()
        #    print(doc["content"])
        outdoc = extract_text_from_document( doc )
        counter, counts = add_doc( outdoc, dicts, counter )
	if (len(counts) == 0):
            counts = {1:1}
        docs[id] = counts
    return docs, dicts

def load_lda_docs_for_inference(db, ids, dicts ):
    docs = {}
    for id in ids:
        print(id)
        doc = db[id]
        outdoc = extract_text_from_document( doc )
        counts = convert_doc_to_count( outdoc, dicts )
	if (len(counts) == 0):
            counts = {1:1}
        docs[id] = counts
    return docs, dicts


def doc_to_vr_lda( doc ):
    return "| " + " ".join([ str(key) + ":" + str(doc[key]) for key in doc ]) + "\n"

def make_vr_lda_input( docs, dicts, filename = "out/vr_lda_input.lda.txt", filenameid = "out/vr_lda_input.ids.txt"):
    file = open( filename, "w+")
    docids = docs.keys()
    docids.sort()
    for docid in docids:
        file.write( doc_to_vr_lda( docs[docid] ) )
        file.write
    file.close()
    
    ifile = open( filenameid, "w" )
    ifile.write( json.dumps([str(docid) for docid in docids], indent=2))
    ifile.close()
    # words
    filenamewords = "out/vr_lda_input.words.txt"
    wfile = open( filenamewords, "w" )
    wfile.write(json.dumps(dicts, indent=2))
    wfile.close()


    return filename, filenameid


def dict_bits( dicts ):
    return int(math.ceil(math.log(len(dicts),2)))
    
def vm_lda_command( filename, topics, dicts ):
    stopics = str(topics)
    bits = dict_bits(dicts)
    # removed cache file
    try:
        os.remove("out/topic-%s.dat.cache" % (stopics))
    except:
        True
    #return " %s --lda %s --lda_alpha 0.1 --lda_rho 0.1 --minibatch 256 --power_t 0.5 --initial_t 1 -b %d --passes 2 -c  -p out/predictions-%s.dat --readable_model out/topics-%s.dat %s" % (
    return " %s --lda %s --lda_alpha 0.1 --lda_rho 0.1 --power_t 0.5 --initial_t 1 -b %d --passes 2 -c  -p out/predictions-%s.dat --readable_model out/topics-%s.dat %s" % (
        "/home/hindle1/src/vowpal_wabbit/vowpalwabbit/vw", 
        stopics,
        bits,
        stopics,
        stopics,
        filename
        )

def vm_lda_inference_command( filename, topics, dicts ):
    stopics = str(topics)
    bits = dict_bits(dicts)

    # removed cache file
    # http://tech.groups.yahoo.com/group/vowpal_wabbit/message/820
    return " %s --lda %s -b %d --testonly -p out/predictions-%s.dat --readable_model out/topics-%s.dat %s" % (
        "/home/hindle1/src/vowpal_wabbit/vowpalwabbit/vw", 
        stopics,
        bits,
        stopics,
        stopics,
        filename
        )


def summarize_topics( n, dicts, readable_model_lines, max_words = 25 ):
    '''  this returns a summary of the topic model as words and a matrix of terms '''
    nlines = len( readable_model_lines )
    topics = [[0 for x in range(0, nlines)] for y in range(0, n)] 
    word = 0
    # we need version 7 now
    if ("Version" in readable_model_lines[0]):
        readable_model_lines.pop(0)
    for line in readable_model_lines:
        if (not (":" in line) and not ("Version" in line)):            
            line = line.rstrip()
            topic = 0
            #print("["+line+"]")
            elms = [float(x) for x in line.split(" ")]
            for topic in range(0, n):
                topics[topic][word] = elms[1+topic]
            word += 1
    # now we have that matrix
    # per each topic find the most prevelant word
    summary = [[] for x in range(0, n)]
    revdict = reverse_dict( dicts )
    for topici in range(0, n):
        topic = topics[topici]
        #print("Topic Length %d" % (len(topic)))
        #print("RevDict Length %d" % (len(revdict)))
        #print("Dicts Length %d" % (len(dicts)))
        indices = range(0,len(topic))
        indices.sort( key = lambda i: topic[i], reverse = True )
        words = [ revdict.get(i,("NOTFOUND: %d" % i)) for i in indices[0:max_words] ]
        summary[ topici ] = words
    return topics , summary

def sorted_indices( x ):
    indices = range(0,len(x))
    indices.sort( key = lambda i: x[i] )
    return indices;
    

def summarize_topics_from_file(n, dicts, readable_model_filename ):
    file = open( readable_model_filename, "r" )
    text = file.readlines()
    file.close()
    return summarize_topics(n, dicts, text )

def summarize_document_topic_matrix(n, lines):
    ''' each line is a set of numbers indicating the topic association '''
    nlines = len( lines )
    docs = [[0 for x in range(0, n)] for y in range(0, nlines)] 
    return [[float(x) for x in line.rstrip().split(" ")] for line in lines]


def summarize_document_topic_matrix_from_file( n, document_topic_matrix_filename ):
    file = open( document_topic_matrix_filename, "r" )
    text = file.readlines()
    file.close()
    return summarize_document_topic_matrix( n, text )

def compact_cosine( dtm, ids, topn = 50 ):
    ''' 
    This function makes a reduced cosine distance, it uses more computation
    but should stay in memory 
    '''
    out = {}
    for i in range(0, len(dtm)):
        l = scipy.spatial.distance.cdist( dtm[i:i+1], dtm[0:], 'cosine' )
        v = l[0]
        indices = sorted_indices(v)[0:topn]
        ol = [{"id":ids[ind],"i":ind,"r":v[ind]} for ind in indices]
        out[ids[i]] = ol
    return out

def nn( dtm, ids, topn = 25, distance = 'kl' ):
    ''' 
    nearest neighbor
    '''
    pyflann.set_distance_type('kl')
    flann = FLANN()
    result, dists = flann.nn(array(dtm),array(dtm), topn)#,algorithm='kmeans')
    out = {}
    for ielm in range(0, len(dtm)):
        indices = result[ielm]        
        v = dists[ielm]
        ol = [{"id":ids[indices[i]],"i":i,"r":v[i]} for i in range(0,len(indices))]
        out[ids[ielm]] = ol
    return out

def main():
    raise Exception("No CouchDB")
    db = connect_to_couchdb()
    ids = get_ids(db)
    #sids = ids[1:100]
    sids = ids
    docs, dicts = load_lda_docs(db, sids)
    filename, _ = make_vr_lda_input( docs, dicts )
    command = vm_lda_command(filename, 20)
    print(command)
    os.system( command )

if __name__ == "__main__":
    main()

#humor me
