import json
import lda
import os
import sys

ntopics = 20

def length(text):
    return len(text)

def dumptojsonfile( filename, data):
    file = open(filename, "w")
    file.write(json.dumps(data, indent=2))
    file.close()

def read_json_file( filename ):
    jsonsdata = open(filename).read()
    data = json.loads(jsonsdata)
    ldocs = [ row["doc"] for row in data["rows"] ]
    docs = {}
    for doc in ldocs:
        docs[doc["_id"]] = doc
    ids = [ doc["_id"] for doc in ldocs ]
    return  docs, ids


def main():
    ldocs, lids = read_json_file("large.json")
    docs, dicts = lda.load_lda_docs(ldocs, lids)
    dumptojsonfile("out/dicts.txt", dicts)
    filename, _ = lda.make_vr_lda_input( docs, dicts )
    command = lda.vm_lda_command(filename, ntopics, dicts)
    print(command)
    os.system( command )

    topics, summary = lda.summarize_topics_from_file( ntopics, dicts, ("out/topics-%s.dat" % ntopics) )
    document_topic_matrix = lda.summarize_document_topic_matrix_from_file( ntopics, ("out/predictions-%s.dat" % ntopics) )
    doc_top_mat_map = dict( (lids[i], document_topic_matrix[i]) for i in range(0,len(lids)) )
    dumptojsonfile("out/lda-topics.txt", topics)
    dumptojsonfile("out/summary.txt", summary)
    dumptojsonfile("out/orig-document_topic_matrix.txt", document_topic_matrix)
    dumptojsonfile("out/orig-document_topic_map.txt", doc_top_mat_map)

    # now we load up the commits.json
    print("Loading commits.json")
    cdocs, cids = read_json_file("commits.json")
    print("%d documents" % length(cdocs))
    mycdocs, _ = lda.load_lda_docs_for_inference( cdocs, cids, dicts )
    filename, _ = lda.make_vr_lda_input( mycdocs, dicts, filename = "out/vr_lda_input_inference.lda.txt", filenameid="out/vr_lda_input_inference.ids.txt" )
    command = lda.vm_lda_inference_command( filename, ntopics, dicts )
    print(command)
    os.system( command )
    topics, summary = lda.summarize_topics_from_file( ntopics, dicts, ("out/topics-%s.dat" % ntopics) )
    document_topic_matrix = lda.summarize_document_topic_matrix_from_file( ntopics, ("out/predictions-%s.dat" % ntopics) )
    doc_top_mat_map = dict( (cids[i], document_topic_matrix[i]) for i in range(0,len(cids)) )
    dumptojsonfile("out/inf-lda-topics.txt", topics)
    dumptojsonfile("out/inf-summary.txt", summary)
    dumptojsonfile("out/document_topic_matrix.txt", document_topic_matrix)
    dumptojsonfile("out/document_topic_map.txt", doc_top_mat_map)

    

# run main

if __name__ == "__main__":
    main()
