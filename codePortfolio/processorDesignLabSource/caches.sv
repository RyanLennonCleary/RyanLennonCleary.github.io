/*
  Eric Villasenor
  evillase@gmail.com

  this block holds the i and d cache
*/


// interfaces
`include "datapath_cache_if.vh"
`include "caches_if.vh"

// cpu types
`include "cpu_types_pkg.vh"

module caches (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
    caches_if cif
);
    import cpu_types_pkg::*;
   
   datapath_cache_if dciif();
   datapath_cache_if dcdif();
   caches_if ciif();
   caches_if cdif();

  // icache
  icache  ICACHE(CLK, nRST, dciif, ciif);
  // dcache
  dcache  DCACHE(CLK, nRST, dcdif, cdif);

   assign cif.dREN = cdif.dREN;
   assign cif.dWEN = cdif.dWEN;
   assign cif.daddr = cdif.daddr;
   assign cif.dstore = cdif.dstore;
   assign cif.iREN = ciif.iREN;
   assign cif.iaddr = ciif.iaddr;
    assign cif.ccwrite = cdif.ccwrite;
    assign cif.cctrans = cdif.cctrans;

   assign cdif.dwait = cif.dwait;
   assign cdif.dload = cif.dload;
   assign ciif.iwait = cif.iwait;
   assign ciif.iload = cif.iload;
    assign cdif.ccwait = cif.ccwait;
    assign cdif.ccinv = cif.ccinv;
    assign cdif.ccsnoopaddr = cif.ccsnoopaddr;

   assign dcif.ihit = dciif.ihit;
   assign dcif.dhit = dcdif.dhit;
   assign dcif.imemload = dciif.imemload;
   assign dcif.dmemload = dcdif.dmemload;
   assign dcif.flushed = dcdif.flushed;

   assign dciif.imemREN = dcif.imemREN;
   assign dciif.imemaddr = dcif.imemaddr;
   assign dcdif.halt = dcif.halt;
   assign dcdif.dmemREN =  dcif.dmemREN;
   assign dcdif.dmemWEN = dcif.dmemWEN;
   assign dcdif.dmemstore = dcif.dmemstore;
   assign dcdif.dmemaddr = dcif.dmemaddr;
   assign dcdif.datomic = dcif.datomic;
   
endmodule
