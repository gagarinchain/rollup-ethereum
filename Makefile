# Go parameters
PROTOS_IN=/Users/dabasov/Projects/gagarin/rollups/protobuff/protos
PROTOS_OUT=/Users/dabasov/Projects/rollups-contract/contracts
PLUGIN=/protoc/plugin/gen_sol.py
PROTO_NAME=rollup.proto

all: test build

protos:
	 docker run --rm -ti -v $(PROTOS_OUT):/out -v $(PROTOS_IN):/in umegaya/pb3sol protoc -I/ -I/protoc/include --plugin=protoc-gen-sol=$(PLUGIN) --sol_out=/out /in/$(PROTO_NAME)
