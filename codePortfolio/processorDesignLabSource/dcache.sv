`include "datapath_cache_if.vh"
`include "caches_if.vh"
`include "cpu_types_pkg.vh"
module dcache(
    input logic CLK,
    input logic nRST,
    datapath_cache_if.dcache dcif,
    caches_if.dcache ciif);
    import cpu_types_pkg::*;
    typedef enum logic [5:0] {
        HALT0 = 6'b000000,
        HALT1 = 6'b000001,
        HALT2 = 6'b000010,
        HALT3 = 6'b000011,
        HALT4 = 6'b000100,
        HALT5 = 6'b000101,
        HALT6 = 6'b000110,
        HALT7 = 6'b000111,
        HALT8 = 6'b001000,
        HALT9 = 6'b001001,
        HALT10 = 6'b001010,
        HALT11 = 6'b001011,
        HALT12 = 6'b001100,
        HALT13 = 6'b001101,
        HALT14 = 6'b001110,
        HALT15 = 6'b001111,
        HALT16 = 6'b010000,
        HALT17 = 6'b010001,
        HALT18 = 6'b010010,
        HALT19 = 6'b010011,
        HALT20 = 6'b010100,
        HALT21 = 6'b010101,
        HALT22 = 6'b010110,
        HALT23 = 6'b010111,
        HALT24 = 6'b011000,
        HALT25 = 6'b011001,
        HALT26 = 6'b011010,
        HALT27 = 6'b011011,
        HALT28 = 6'b011100,
        HALT29 = 6'b011101,
        HALT30 = 6'b011110,
        HALT31 = 6'b011111,
        CHECK = 6'b100000,
        EVICT_LRU1 = 6'b100001,
        EVICT_LRU2 = 6'b100010,
        FILL_LRU1 = 6'b100011,
        FILL_LRU2 = 6'b100100,
        STOP = 6'b100101,
        COHERENCECHECK = 6'b100110,
        COHERENCEWB1 = 6'b100111,
        COHERENCEWB2 = 6'b101000,
        FILL0_1 = 6'b101001,
        FILL0_2 = 6'b101010,
        FILL1_1 = 6'b101011,
        FILL1_2 = 6'b101100,
        STOP2 = 6'b101101,
        STOP3 = 6'b101110
    } state_t;
    word_t link, next_link;
    logic link_valid, next_link_valid;
    state_t state, next_state;
    dcache_frame [1:0][7:0] dcache, next_dcache;
    logic [7:0] LRU, next_LRU;
    logic [15:0]      dirty_cct;
    dcachef_t addr;
    logic [1:0] replace;
    logic both_valid;
    logic word;
    logic [3:0] i, next_i;
    logic [3:0] i_plus_one;
    logic [2:0] i_three_to_one;
    logic i_zero;
    logic flushed,next_flushed;
    word_t  hit_counter, next_hit_counter;
    logic halt_dirty_valid;
    word_t halt1_daddr,halt2_daddr;
    word_t halt1_dstore;
    word_t halt2_dstore;
    word_t miss_clean_daddr1;
    word_t miss_clean_daddr2;
    word_t miss_dirty_daddr1;
    word_t miss_dirty_daddr2;
    word_t miss_dirty_dstore1;
    word_t miss_dirty_dstore2;
    logic check_f0_tag_v_ren;
    logic check_f0_tag_v_wen;
    logic check_f1_tag_v_ren;
    logic check_f1_tag_v_wen;
    word_t check_f0_dmemload;
    word_t check_f1_dmemload;
    logic lru;
    logic go_to_miss_dirty;
    dcachef_t  snoopaddr, next_snoopaddr;
    logic coherence_check0;
    logic coherence_check1;
    logic frame, next_frame;
    logic sw, next_sw;
    logic [5:0] state_plus_one;
    logic invalidate_frame0;
    logic invalidate_frame1;
    logic  match0,match1;
    logic  valid0, valid1;
    logic  dirty0, dirty1;


    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            dcache <= '0;
            state <= CHECK;
            LRU <= '0;
            i <= '0;
            hit_counter <= '0;
            frame <= '0;
            sw <= '0;
            snoopaddr <= dcachef_t'(32'h0);
            link <= '0;
            link_valid <= '0;
        end
        else begin
            dcache <= next_dcache;
            state <= next_state;
            LRU <= next_LRU;
            i <= next_i;
            hit_counter <= next_hit_counter;
            frame <= next_frame;
            sw <= next_sw;
            snoopaddr <= next_snoopaddr;
            link <= next_link;
            link_valid <= next_link_valid;
        end
    end


    always_comb begin
        next_state = state;
        casez(state)
            CHECK: begin
                //NEW LOGIC FOR CHECK
                if(dcif.dmemWEN || dcif.dmemREN) begin
                    if(match0 && valid0 && dirty0) next_state = CHECK;
                    else if (match0 && valid0 && !dirty0) next_state = CHECK;
                    else if (match0 && !valid0) begin
                        if(match1 && valid1 && dirty1) next_state = CHECK;
                        else if (match1 && valid1 && !dirty1) next_state = CHECK;
                        else if(match1 && !valid1) next_state = FILL_LRU1;
                        else if(!match1 && valid1 && dirty1) next_state = FILL0_1;
                        else if(!match1 && valid1 && !dirty1) next_state = FILL0_1;
                        else if(!match1 && !valid1) next_state = FILL_LRU1;
                    end
                    else if(!match0 && valid0 && dirty0) begin
                        if(match1 && valid1 && dirty1) next_state = CHECK;
                        else if (match1 && valid1 && !dirty1) next_state = CHECK;
                        else if(match1 && !valid1) next_state = FILL1_1;
                        else if(!match1 && valid1 && dirty1) next_state = EVICT_LRU1;
                        else if(!match1 && valid1 && !dirty1) next_state = FILL1_1;
                        else if(!match1 && !valid1) next_state = FILL1_1;
                    end
                    else if(!match0 && valid0 && !dirty0) begin
                        if(match1 && valid1 && dirty1) next_state = CHECK;
                        else if (match1 && valid1 && !dirty1) next_state = CHECK;
                        else if(match1 && !valid1) next_state = FILL1_1;
                        else if(!match1 && valid1 && dirty1) next_state = FILL0_1;
                        else if(!match1 && valid1 && !dirty1) next_state = FILL_LRU1;
                        else if(!match1 && !valid1) next_state = FILL1_1;
                    end
                    else if(!match0 && !valid0) begin
                        if(match1 && valid1 && dirty1) next_state = CHECK;
                        else if (match1 && valid1 && !dirty1) next_state = CHECK;
                        else if(match1 && !valid1) next_state = FILL1_1;
                        else if(!match1 && valid1 && dirty1) next_state = FILL0_1;
                        else if(!match1 && valid1 && !dirty1) next_state = FILL0_1;
                        else if(!match1 && !valid1) next_state = FILL_LRU1;
                    end
                end // if (dcif.dmemWEN || dcif.dmemREN)

                //override dmemWEN coherence miss case
                if(dcif.dmemWEN) begin
                    if (match0 && valid0 && !dirty0) next_state = FILL0_1;
                    else if (match1 && valid1 && !dirty1) next_state = FILL1_1;
                end

                if(dcif.halt) next_state = HALT0;
                if(ciif.ccwait == 1'b1) next_state = COHERENCECHECK;
            end
            FILL_LRU1:begin
                if (ciif.ccwait) next_state = COHERENCECHECK;
                else if(ciif.dwait) next_state = FILL_LRU1;
                else next_state = FILL_LRU2;
            end
            FILL_LRU2:begin
                if(ciif.dwait) next_state = FILL_LRU2;
                else next_state = CHECK;
            end
            FILL0_1:begin
                if (ciif.ccwait) next_state = COHERENCECHECK;
                else if(ciif.dwait) next_state = FILL0_1;
                else next_state = FILL0_2;
            end
            FILL0_2:begin
                if(ciif.dwait) next_state = FILL0_2;
                else next_state = CHECK;
            end
            FILL1_1:begin
                if (ciif.ccwait) next_state = COHERENCECHECK;
                else if(ciif.dwait) next_state = FILL1_1;
                else next_state = FILL1_2;
            end
            FILL1_2:begin
                if(ciif.dwait) next_state = FILL1_2;
                else next_state = CHECK;
            end

            EVICT_LRU1:begin
                if (ciif.ccwait) next_state = COHERENCECHECK;
                else if(ciif.dwait) next_state = EVICT_LRU1;
                else next_state = EVICT_LRU2;
            end
            EVICT_LRU2:begin
                if(ciif.dwait) next_state = EVICT_LRU2;
                else next_state = CHECK;
            end
            HALT0,
            HALT1,
            HALT2,
            HALT3,
            HALT4,
            HALT5,
            HALT6,
            HALT7,
            HALT8,
            HALT9,
            HALT10,
            HALT11,
            HALT12,
            HALT13,
            HALT14,
            HALT15,
            HALT16,
            HALT17,
            HALT18,
            HALT19,
            HALT20,
            HALT21,
            HALT22,
            HALT23,
            HALT24,
            HALT25,
            HALT26,
            HALT27,
            HALT28,
            HALT29,
            HALT30: begin
                if (ciif.ccwait == 1'b1) next_state = COHERENCECHECK;
                else if (halt_dirty_valid) begin
                    if (ciif.dwait == 1'b0) begin
                        next_state = state_t'(state_plus_one);
                    end
                end
                else begin
                    next_state = state_t'(state_plus_one);
                end
            end
            HALT31: begin
                if (ciif.ccwait == 1'b1) next_state = COHERENCECHECK;
                else if (halt_dirty_valid) begin
                    if (ciif.dwait == 1'b0) begin
                        next_state = STOP;
                    end
                end
                else begin
                    next_state = STOP;
                end
            end
            STOP: begin
                if (ciif.ccwait == 1'b1) next_state = COHERENCECHECK;
                else if (halt_dirty_valid) begin
                    if (ciif.dwait == 1'b0) begin
                        next_state = STOP2;
                    end
                end
                else begin
                    next_state = STOP2;
                end
            end // case: STOP
            STOP2: begin
                if (ciif.ccwait == 1'b1) next_state = COHERENCECHECK;
                else if (halt_dirty_valid) begin
                    if (ciif.dwait == 1'b0) begin
                        next_state = STOP3;
                    end
                end
                else begin
                    next_state = STOP3;
                end
            end
            STOP3: begin
                next_state = STOP3;
            end
            COHERENCECHECK:begin
                if (coherence_check0 || coherence_check1) begin
                    next_state = COHERENCEWB1;
                end
                else begin
                    next_state = CHECK;
                end
            end
            COHERENCEWB1: begin
                if (ciif.dwait == 1'b0) begin
                    next_state = COHERENCEWB2;
                end
                else begin
                    next_state = COHERENCEWB1;
                end
            end
            COHERENCEWB2: begin
                if (ciif.dwait == 1'b0) begin
                    next_state = CHECK;
                end
                else begin
                    next_state = COHERENCEWB2;
                end
            end
        endcase
    end // always_comb

    //dcif.dmemload
    always_comb begin
        if (dcif.datomic && dcif.dmemWEN && link != word_t'(addr) && link_valid == 1'b0) begin
            dcif.dmemload = '0;
        end
        else if (dcif.datomic && dcif.dmemWEN && link == word_t'(addr) && link_valid == 1'b1) begin
            dcif.dmemload = 1'b1;
        end
        else if(check_f0_tag_v_ren) dcif.dmemload = check_f0_dmemload;
        else dcif.dmemload = check_f1_dmemload;
    end

    ///*********************COMB2 OUTPUT LOGIC******************************
    always_comb begin
        next_i = i;
        next_dcache = dcache;
        next_hit_counter = hit_counter;
        dcif.flushed = 1'b0;
        next_LRU = LRU;
        dcif.dhit = 1'b0;
        ciif.dREN = 1'b0;
        ciif.dWEN = 1'b0;
        ciif.dstore = 32'b0;
        ciif.daddr = 32'h0;
        ciif.dstore = '0;
        word = 1'b0;
        next_frame = frame;
        next_sw = sw;
        ciif.ccwrite = 1'b0;
        ciif.cctrans = 1'b0;
        //next_snoopaddr = snoopaddr;
        next_link_valid = link_valid;
        next_link = link;
        casez(state)
            CHECK: begin
                if (dcif.datomic && dcif.dmemWEN && link != word_t'(addr)) begin
                    dcif.dhit = 1'b1;
                end
                else if (check_f0_tag_v_ren) begin
                    dcif.dhit = 1'b1;
                    next_LRU[addr.idx] = 1'b1;
                    if(dcif.datomic) begin
                        next_link = dcif.dmemaddr;
                        next_link_valid = '1;
                    end
                end
                else if (check_f0_tag_v_wen) begin
                    dcif.dhit = 1'b1;
                    word = dcif.dmemaddr[2];
                    next_dcache[0][addr.idx].data[word] = dcif.dmemstore;
                    next_LRU[addr.idx] = 1'b1;
                    if(dcif.dmemaddr == link) begin
                        next_link = link + 1'b1;
                        next_link_valid = '0;
                    end
                end
                else if (check_f1_tag_v_ren) begin
                    dcif.dhit = 1'b1;
                    next_LRU[addr.idx] = 1'b0;
                    if(dcif.datomic) begin
                        next_link = dcif.dmemaddr;
                        next_link_valid = '1;
                    end
                end
                else if (check_f1_tag_v_wen) begin
                    dcif.dhit = 1'b1;
                    word = dcif.dmemaddr[2];
                    next_dcache[1][addr.idx].data[word] = dcif.dmemstore;
                    next_LRU[addr.idx] = 1'b0;
                    if(dcif.dmemaddr == link) begin
                        next_link = link + 1'b1;
                        next_link_valid = '0;
                    end
                end

                else begin //miss
                    if(dcif.dmemREN || dcif.dmemWEN) begin
                        next_sw = dcif.dmemWEN;
                    end
                end
            end
            FILL_LRU1:begin
                ciif.dREN = 1'b1;
                ciif.daddr = miss_clean_daddr1;
                if (ciif.dwait == 0) begin
                    next_dcache[lru][addr.idx].data[0] = ciif.dload;
                end
                ciif.ccwrite = sw;
            end
            FILL_LRU2:begin
                ciif.dREN = 1'b1;
                ciif.daddr = miss_clean_daddr2;
                if (ciif.dwait == 0) begin
                    next_dcache[lru][addr.idx].data[1] = ciif.dload;
                    next_dcache[lru][addr.idx].valid = 1;
                    next_dcache[lru][addr.idx].tag = addr.tag;
                    next_dcache[lru][addr.idx].dirty = sw;
                end
                if (dcache[!lru][addr.idx].tag == addr.tag) begin
                    next_dcache[!lru][addr.idx].valid = 1'b0;
                end
                /*
                if (dcif.datomic) begin
                next_link = word_t'(addr);
                next_link_valid = 1'b1;
            end*/
            end // case: FILL_LRU2

            FILL0_1:begin
                ciif.dREN = 1'b1;
                ciif.daddr = miss_clean_daddr1;
                if (ciif.dwait == 0) begin
                    next_dcache[0][addr.idx].data[0] = ciif.dload;
                end
                ciif.ccwrite = sw;
            end
            FILL0_2:begin
                ciif.dREN = 1'b1;
                ciif.daddr = miss_clean_daddr2;
                if (ciif.dwait == 0) begin
                    next_dcache[0][addr.idx].data[1] = ciif.dload;
                    next_dcache[0][addr.idx].valid = 1;
                    next_dcache[0][addr.idx].tag = addr.tag;
                    next_dcache[0][addr.idx].dirty = sw;
                end
                if (dcache[1][addr.idx].tag == addr.tag) begin
                    next_dcache[1][addr.idx].valid = 1'b0;
                end
                /*if (dcif.datomic) begin
                    next_link = word_t'(addr);
                    next_link_valid = 1'b1;
            end*/
            end // case: FILL0_2

            FILL1_1:begin
                ciif.dREN = 1'b1;
                ciif.daddr = miss_clean_daddr1;
                if (ciif.dwait == 0) begin
                    next_dcache[1][addr.idx].data[0] = ciif.dload;
                end
                ciif.ccwrite = sw;
            end
            FILL1_2:begin
                ciif.dREN = 1'b1;
                ciif.daddr = miss_clean_daddr2;
                if (ciif.dwait == 0) begin
                    next_dcache[1][addr.idx].data[1] = ciif.dload;
                    next_dcache[1][addr.idx].valid = 1;
                    next_dcache[1][addr.idx].tag = addr.tag;
                    next_dcache[1][addr.idx].dirty = sw;
                end
                if (dcache[0][addr.idx].tag == addr.tag) begin
                    next_dcache[0][addr.idx].valid = 1'b0;
                end
                /*if (dcif.datomic) begin
                    next_link = word_t'(addr);
                    next_link_valid = 1'b1;
            end*/
            end

            EVICT_LRU1:begin
                ciif.dWEN = 1'b1;
                ciif.daddr = miss_dirty_daddr1;
                ciif.dstore = miss_dirty_dstore1;
            end
            EVICT_LRU2:begin
                ciif.dWEN = 1'b1;
                ciif.daddr = miss_dirty_daddr2;
                ciif.dstore = miss_dirty_dstore2;
                next_dcache[lru][addr.idx].dirty = 1'b0;
            end
            STOP: begin
                next_dcache[1][7].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][7].valid = 1'b0; //turn off valid bit
                ciif.cctrans = 1'b1;
                ciif.ccwrite = 1'b0;
            end
            STOP3: begin
                dcif.flushed = 1'b1;
                ciif.cctrans = 1'b1;
                ciif.ccwrite = 1'b0;
            end
            COHERENCECHECK: begin
                if (coherence_check0) begin
                    next_frame = 1'b0;
                end
                else begin
                    next_frame = 1'b1;
                end
                ciif.cctrans = 1'b1;
                ciif.ccwrite = coherence_check0 || coherence_check1;
                if(ciif.ccinv == 1'b1 && invalidate_frame0) begin
                    //invalidate both frames for now
                    next_dcache[0][snoopaddr.idx].valid = 1'b0;

                end
                if (ciif.ccinv == 1'b1 && invalidate_frame1) begin
                    next_dcache[1][snoopaddr.idx].valid = 1'b0;
                end
                if (ciif.ccinv && word_t'(snoopaddr) == link) begin
                    next_link = '0;
                    next_link_valid = 1'b0;
                end



            end
            COHERENCEWB1: begin
                /*if (coherence_check0) begin
                    ciif.dstore = dcache[0][snoopaddr.idx].data[0];
                    //next_frame = 1'b0;
            end
                    else begin
                    ciif.dstore = dcache[1][snoopaddr.idx].data[0];
                    //next_frame = 1'b1;
            end*/
                    ciif.dstore = dcache[frame][snoopaddr.idx].data[0];
            end
            COHERENCEWB2: begin
                ciif.dstore = dcache[frame][snoopaddr.idx].data[1];
                next_dcache[next_frame][snoopaddr.idx].dirty = 1'b0;
            end
            HALT0: begin
                ciif.daddr = {dcache[0][0].tag, 3'b000, 3'b000};
                ciif.dstore = dcache[0][0].data[0];
                ciif.dWEN = dcache[0][0].dirty && dcache[0][0].valid;
            end
            HALT1: begin
                ciif.daddr = {dcache[0][0].tag, 3'b000, 3'b100};
                ciif.dstore = dcache[0][0].data[1];
                ciif.dWEN = dcache[0][0].dirty && dcache[0][0].valid;
            end
            HALT2: begin
                ciif.daddr = {dcache[1][0].tag, 3'b000, 3'b000};
                ciif.dstore = dcache[1][0].data[0];
                ciif.dWEN = dcache[1][0].dirty && dcache[1][0].valid;
                next_dcache[0][0].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][0].valid = 1'b0; //turn off valid bit
            end
            HALT3: begin
                ciif.daddr = {dcache[1][0].tag, 3'b000, 3'b100};
                ciif.dstore = dcache[1][0].data[1];
                ciif.dWEN = dcache[1][0].dirty && dcache[1][0].valid;
            end
            HALT4: begin
                ciif.daddr = {dcache[0][1].tag, 3'b001, 3'b000};
                ciif.dstore = dcache[0][1].data[0];
                ciif.dWEN = dcache[0][1].dirty && dcache[0][1].valid;
                next_dcache[1][0].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][0].valid = 1'b0; //turn off valid bit
            end
            HALT5: begin
                ciif.daddr = {dcache[0][1].tag, 3'b001, 3'b100};
                ciif.dstore = dcache[0][1].data[1];
                ciif.dWEN = dcache[0][1].dirty && dcache[0][1].valid;
            end
            HALT6: begin
                ciif.daddr = {dcache[1][1].tag, 3'b001, 3'b000};
                ciif.dstore = dcache[1][1].data[0];
                ciif.dWEN = dcache[1][1].dirty && dcache[1][1].valid;
                next_dcache[0][1].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][1].valid = 1'b0; //turn off valid bit
            end
            HALT7: begin
                ciif.daddr = {dcache[1][1].tag, 3'b001, 3'b100};
                ciif.dstore = dcache[1][1].data[1];
                ciif.dWEN = dcache[1][1].dirty && dcache[1][1].valid;
            end
            HALT8: begin
                ciif.daddr = {dcache[0][2].tag, 3'b010, 3'b000};
                ciif.dstore = dcache[0][2].data[0];
                ciif.dWEN = dcache[0][2].dirty && dcache[0][2].valid;
                next_dcache[1][1].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][1].valid = 1'b0; //turn off valid bit
            end
            HALT9: begin
                ciif.daddr = {dcache[0][2].tag, 3'b010, 3'b100};
                ciif.dstore = dcache[0][2].data[1];
                ciif.dWEN = dcache[0][2].dirty && dcache[0][2].valid;
            end
            HALT10: begin
                ciif.daddr = {dcache[1][2].tag, 3'b010, 3'b000};
                ciif.dstore = dcache[1][2].data[0];
                ciif.dWEN = dcache[1][2].dirty && dcache[1][2].valid;
                next_dcache[0][2].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][2].valid = 1'b0; //turn off valid bit
            end
            HALT11: begin
                ciif.daddr = {dcache[1][2].tag, 3'b010, 3'b100};
                ciif.dstore = dcache[1][2].data[1];
                ciif.dWEN = dcache[1][2].dirty && dcache[1][2].valid;
            end
            HALT12: begin
                ciif.daddr = {dcache[0][3].tag, 3'b011, 3'b000};
                ciif.dstore = dcache[0][3].data[0];
                ciif.dWEN = dcache[0][3].dirty && dcache[0][3].valid;
                next_dcache[1][2].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][2].valid = 1'b0; //turn off valid bit
            end
            HALT13: begin
                ciif.daddr = {dcache[0][3].tag, 3'b011, 3'b100};
                ciif.dstore = dcache[0][3].data[1];
                ciif.dWEN = dcache[0][3].dirty && dcache[0][3].valid;
            end
            HALT14: begin
                ciif.daddr = {dcache[1][3].tag, 3'b011, 3'b000};
                ciif.dstore = dcache[1][3].data[0];
                ciif.dWEN = dcache[1][3].dirty && dcache[1][3].valid;
                next_dcache[0][3].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][3].valid = 1'b0; //turn off valid bit
            end
            HALT15: begin
                ciif.daddr = {dcache[1][3].tag, 3'b011, 3'b100};
                ciif.dstore = dcache[1][3].data[1];
                ciif.dWEN = dcache[1][3].dirty && dcache[1][3].valid;
            end
            HALT16: begin
                ciif.daddr = {dcache[0][4].tag, 3'b100, 3'b000};
                ciif.dstore = dcache[0][4].data[0];
                ciif.dWEN = dcache[0][4].dirty && dcache[0][4].valid;
                next_dcache[1][3].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][3].valid = 1'b0; //turn off valid bit
            end
            HALT17: begin
                ciif.daddr = {dcache[0][4].tag, 3'b100, 3'b100};
                ciif.dstore = dcache[0][4].data[1];
                ciif.dWEN = dcache[0][4].dirty && dcache[0][4].valid;
            end
            HALT18: begin
                ciif.daddr = {dcache[1][4].tag, 3'b100, 3'b000};
                ciif.dstore = dcache[1][4].data[0];
                ciif.dWEN = dcache[1][4].dirty && dcache[1][4].valid;
                next_dcache[0][4].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][4].valid = 1'b0; //turn off valid bit
            end
            HALT19: begin
                ciif.daddr = {dcache[1][4].tag, 3'b100, 3'b100};
                ciif.dstore = dcache[1][4].data[1];
                ciif.dWEN = dcache[1][4].dirty && dcache[1][4].valid;
            end
            HALT20: begin
                ciif.daddr = {dcache[0][5].tag, 3'b101, 3'b000};
                ciif.dstore = dcache[0][5].data[0];
                ciif.dWEN = dcache[0][5].dirty && dcache[0][5].valid;
                next_dcache[1][4].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][4].valid = 1'b0; //turn off valid bit
            end
            HALT21: begin
                ciif.daddr = {dcache[0][5].tag, 3'b101, 3'b100};
                ciif.dstore = dcache[0][5].data[1];
                ciif.dWEN = dcache[0][5].dirty && dcache[0][5].valid;
            end
            HALT22: begin
                ciif.daddr = {dcache[1][5].tag, 3'b101, 3'b000};
                ciif.dstore = dcache[1][5].data[0];
                ciif.dWEN = dcache[1][5].dirty && dcache[1][5].valid;
                next_dcache[0][5].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][5].valid = 1'b0; //turn off valid bit
            end
            HALT23: begin
                ciif.daddr = {dcache[1][5].tag, 3'b101, 3'b100};
                ciif.dstore = dcache[1][5].data[1];
                ciif.dWEN = dcache[1][5].dirty && dcache[1][5].valid;
            end
            HALT24: begin
                ciif.daddr = {dcache[0][6].tag, 3'b110, 3'b000};
                ciif.dstore = dcache[0][6].data[0];
                ciif.dWEN = dcache[0][6].dirty && dcache[0][6].valid;
                next_dcache[1][5].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][5].valid = 1'b0; //turn off valid bit
            end
            HALT25: begin
                ciif.daddr = {dcache[0][6].tag, 3'b110, 3'b100};
                ciif.dstore = dcache[0][6].data[1];
                ciif.dWEN = dcache[0][6].dirty && dcache[0][6].valid;
            end
            HALT26: begin
                ciif.daddr = {dcache[1][6].tag, 3'b110, 3'b000};
                ciif.dstore = dcache[1][6].data[0];
                ciif.dWEN = dcache[1][6].dirty && dcache[1][6].valid;
                next_dcache[0][6].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][6].valid = 1'b0; //turn off valid bit
            end
            HALT27: begin
                ciif.daddr = {dcache[1][6].tag, 3'b110, 3'b100};
                ciif.dstore = dcache[1][6].data[1];
                ciif.dWEN = dcache[1][6].dirty && dcache[1][6].valid;
            end
            HALT28: begin
                ciif.daddr = {dcache[0][7].tag, 3'b111, 3'b000};
                ciif.dstore = dcache[0][7].data[0];
                ciif.dWEN = dcache[0][7].dirty && dcache[0][7].valid;
                next_dcache[1][6].dirty = 1'b0; //turn off dirty bit
                next_dcache[1][6].valid = 1'b0; //turn off valid bit
            end
            HALT29: begin
                ciif.daddr = {dcache[0][7].tag, 3'b111, 3'b100};
                ciif.dstore = dcache[0][7].data[1];
                ciif.dWEN = dcache[0][7].dirty && dcache[0][7].valid;
            end
            HALT30: begin
                ciif.daddr = {dcache[1][7].tag, 3'b111, 3'b000};
                ciif.dstore = dcache[1][7].data[0];
                ciif.dWEN = dcache[1][7].dirty && dcache[1][7].valid;
                next_dcache[0][7].dirty = 1'b0; //turn off dirty bit
                next_dcache[0][7].valid = 1'b0; //turn off valid bit
            end
            HALT31: begin
                ciif.daddr = {dcache[1][7].tag, 3'b111, 3'b100};
                ciif.dstore = dcache[1][7].data[1];
                ciif.dWEN = dcache[1][7].dirty && dcache[1][7].valid;
            end
        endcase
    end

    assign addr = dcachef_t'({16'h0000,dcif.dmemaddr[15:0]});
    assign next_snoopaddr = dcachef_t'({16'h0000,ciif.ccsnoopaddr[15:0]});
    assign both_valid = dcache[0][addr.idx].valid && dcache[1][addr.idx].valid;
    assign replace = (both_valid && (lru == 2'd1)) ? 2'd0 :
                     both_valid && (lru == 2'd0) ? 2'd1 : 2'd2;
    assign halt_dirty_valid = dcache[state[1]][state[5:2]].dirty == 1'b1 && dcache[state[1]][state[5:2]].valid;
    assign halt1_daddr = {dcache[i[0]][i[3:1]].tag, i[3:1], 3'b000};
    assign halt2_daddr = {dcache[i[0]][i[3:1]].tag, i[3:1], 3'b100};
    assign halt1_dstore = dcache[i[0]][i[3:1]].data[0];
    assign halt2_dstore = dcache[i[0]][i[3:1]].data[1];
    assign miss_clean_daddr1 = {dcif.dmemaddr[31:3],3'b000};
    assign miss_clean_daddr2 = {dcif.dmemaddr[31:3],3'b100};
    assign miss_dirty_daddr1 = {dcache[lru][addr.idx].tag, addr.idx, 3'b000};
    assign miss_dirty_daddr2 = {dcache[lru][addr.idx].tag, addr.idx, 3'b100};
    assign lru = LRU[addr.idx];
    assign miss_dirty_dstore1 = dcache[lru][addr.idx].data[0];
    assign miss_dirty_dstore2 = dcache[lru][addr.idx].data[1];
    assign check_f0_tag_v_ren= dcache[0][addr.idx].tag == addr.tag && dcache[0][addr.idx].valid && dcif.dmemREN;
    assign check_f0_tag_v_wen= dcache[0][addr.idx].tag == addr.tag && dcache[0][addr.idx].valid && dcif.dmemWEN && dcache[0][addr.idx].dirty;
    assign check_f1_tag_v_ren= dcache[1][addr.idx].tag == addr.tag && dcache[1][addr.idx].valid && dcif.dmemREN;
    assign check_f1_tag_v_wen = dcache[1][addr.idx].tag == addr.tag && dcache[1][addr.idx].valid && dcif.dmemWEN && dcache[1][addr.idx].dirty;
    assign check_f0_dmemload =dcache[0][addr.idx].data[addr.blkoff];
    assign check_f1_dmemload =dcache[1][addr.idx].data[addr.blkoff];
    assign go_to_miss_dirty = (dcache[0][addr.idx].dirty || dcache[1][addr.idx].dirty) && (replace != 2'd2);
    assign i_plus_one = i + 1;
    assign i_zero = i[0];
    assign i_three_to_one = i[3:1];
    assign coherence_check0 = (dcache[0][snoopaddr.idx].tag == snoopaddr.tag && dcache[0][snoopaddr.idx].dirty);
    assign coherence_check1 = (dcache[1][snoopaddr.idx].tag == snoopaddr.tag && dcache[1][snoopaddr.idx].dirty);
    assign state_plus_one = state + 1'b1;
    assign invalidate_frame0 = (dcache[0][snoopaddr.idx].tag == snoopaddr.tag);
    assign invalidate_frame1 = (dcache[1][snoopaddr.idx].tag == snoopaddr.tag);

    assign match0 = dcache[0][addr.idx].tag == addr.tag;
    assign match1 = dcache[1][addr.idx].tag == addr.tag;
    assign valid0 = dcache[0][addr.idx].valid;
    assign valid1 = dcache[1][addr.idx].valid;
    assign dirty0 = dcache[0][addr.idx].dirty;
    assign dirty1 = dcache[1][addr.idx].dirty;
endmodule
