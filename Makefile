ROOT=$(shell pwd)
INC=$(ROOT)/lib/inc
MUTEXDIR=$(ROOT)/lib/mutex
USERINC=$(ROOT)/user/structures
TESTDIR=$(ROOT)/user/tests

CXX=g++
CXXFLAGS=-I$(INC) -O1 -Wall -mrtm -fopenmp

rtmfile=$(if $(filter ${M},rtm),$(MUTEXDIR)/mutex_transaction_rtm.o, )
rtmadfile=$(if $(filter ${M},rtmad),$(MUTEXDIR)/mutex_rtm_adapt.o, )
spinfile=$(if $(filter ${M},spin),$(MUTEXDIR)/mutex_spin.o, )
qvolfile=$(if $(filter ${M},qvol),$(MUTEXDIR)/mutex_queue_vol.o, )
qflushfile=$(if $(filter ${M},qflush),$(MUTEXDIR)/mutex_queue_flush.o, )
mcsfile=$(if $(filter ${M},mcs),$(MUTEXDIR)/mutex_mcs_queue.o, )
hlefile=$(if $(filter ${M},hle),$(MUTEXDIR)/mutex_transaction_hle.o, )

DEL_OBJS=$(MUTEXDIR)/mutex_transaction_rtm.o $(MUTEXDIR)/mutex_spin.o\
					$(MUTEXDIR)/mutex_queue_vol.o $(MUTEXDIR)/mutex_queue_flush.o\
					$(MUTEXDIR)/mutex_mcs_queue.o $(MUTEXDIR)/mutex_transaction_hle.o\
					$(MUTEXDIR)/mutex_rtm_adapt.o


OBJS=$(rtmfile) $(spinfile) $(qvolfile) $(qflushfile)\
			$(mcsfile) $(hlefile) $(rtmadfile) $(USERINC)/ll_fine_grained.o \
			$(USERINC)/ll_coarse_grained.o

TESTS=$(TESTDIR)/test_small_critical $(TESTDIR)/test_ll_fine\
			$(TESTDIR)/test_ll_coarse $(TESTDIR)/test_variable_critical\

# M=rtm | M=spin | M=qvol | M=qflush | M=mcs | m=hle
rtm = $(if $(filter ${M},rtm),MUTEX_TRANSACTION_RTM, )
rtmad = $(if $(filter ${M},rtmad),MUTEX_RTM_ADAPT, )
spin = $(if $(filter ${M},spin),MUTEX_SPIN, )
qvol = $(if $(filter ${M},qvol),MUTEX_QUEUE_VOL, )
qflush = $(if $(filter ${M},qflush),MUTEX_QUEUE_FLUSH, )
mcs = $(if $(filter ${M},mcs),MUTEX_MCS_QUEUE, )
hle = $(if $(filter ${M},hle),MUTEX_TRANSACTION_HLE, )

# ML=myield | ML=mprop | ML=mexp
myield = $(if $(filter ${ML},myield),-D YIELD_LOOP, )
mprop = $(if $(filter ${ML},mprop),-D PROP_BACKOFF_LOOP, )
mexp = $(if $(filter ${ML},mexp),-D EXP_BACKOFF_LOOP, )

# mutex wait time T=1 or T=somethignelse
time = $(if $(filter ${MT},1),-D WAIT_TIME, )

dropped = $(if $(filter ${MD},1),-D DROPPED_COUNT, )

#test for omp critical section usage
ompcrit = $(if $(filter ${O},1),-D USE_OMP_CRIT, )

testtime = $(if $(filter ${TT},1),-D TOT_TIME, )

# first clean, then the object files and then the tests
all: clean $(OBJS) $(TESTS)

includes = $(wildcard $(INC)/*.h)


%: %.cpp ${includes} $(OBJS)
	$(CXX) $(CXXFLAGS) $(ompcrit) $(testtime) -D $(rtm) $(spin) $(qvol) $(qflush)\
	$(mcs) $(hle) $(rtmad) -std=c++11 $(OBJS) $< -o $@

%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) -c -o $@

%.o: %.c
	$(CXX) $(CXXFLAGS) -D $(rtm) $(spin) $(qvol) $(qflush) $(mcs) $(hle) \
	$(rtmad) $(myield) $(mprop) $(mexp) $(time) $(dropped) -c -o $@ $<

%.o: %.S
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -rf $(DEL_OBJS) $(TESTS)