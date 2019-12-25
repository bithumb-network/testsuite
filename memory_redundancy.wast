;; Test that optimizers don't do redundant-load, store-to-load, or dead-store
;; optimizations when there are interfering stores, even of different types
;; and to non-identical addresses.

(module
  (memory 1 1)

  (func (export "zero_everything")
    (i32.store (i32.const 0) (i32.const 0))
    (i32.store (i32.const 4) (i32.const 0))
    (i32.store (i32.const 8) (i32.const 0))
    (i32.store (i32.const 12) (i32.const 0))
  )

  (func (export "test_redundant_load") (result i32)
    (local $t i32)
    (local $s i32)
    (local.set $t (i32.load (i32.const 8)))
    (i32.store (i32.const 5) (i32.const 0x80000000))
    (local.set $s (i32.load (i32.const 8)))
    (i32.add (local.get $t) (local.get $s))
  )

  ;; A function named "malloc" which implementations nonetheless shouldn't
  ;; assume behaves like C malloc.
  (func $malloc (export "malloc")
     (param $size i32)
     (result i32)
     (i32.const 16)
  )

  ;; Call malloc twice, but unlike C malloc, we don't get non-aliasing pointers.
  (func (export "malloc_aliasing")
     (result i32)
     (local $x i32)
     (local $y i32)
     (local.set $x (call $malloc (i32.const 4)))
     (local.set $y (call $malloc (i32.const 4)))
     (i32.store (local.get $x) (i32.const 42))
     (i32.store (local.get $y) (i32.const 43))
     (i32.load (local.get $x))
  )
)

(invoke "zero_everything")
(assert_return (invoke "test_redundant_load") (i32.const 0x00000080))
(invoke "zero_everything")
(invoke "zero_everything")
(assert_return (invoke "malloc_aliasing") (i32.const 43))
