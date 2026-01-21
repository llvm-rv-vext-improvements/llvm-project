target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

define void @abc(i64 %0, ptr %1) #0 {
newFuncRoot:
  br label %if.else43

if.else43:                                        ; preds = %newFuncRoot
  %conv44 = sitofp i64 %0 to double
  %div45 = fdiv double %conv44, 1.000000e+03
  %2 = tail call double @llvm.ceil.f64(double %div45)
  %conv46 = fptosi double %2 to i32
  %div48 = fdiv double %conv44, 1.000000e+01
  %3 = tail call double @llvm.ceil.f64(double %div48)
  %conv49 = fptosi double %3 to i32
  %cmp52.not170 = icmp sgt i32 %conv46, %conv49
  br label %exit.exitStub

exit.exitStub:                                    ; preds = %if.else43
  store i1 %cmp52.not170, ptr %1, align 1
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.ceil.f64(double) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #1

attributes #0 = { "target-features"="+m,+a,+f,+d,+c,+v" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

