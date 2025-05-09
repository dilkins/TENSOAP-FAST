program sagpr_get_kernel
    use sagpr
    use iso_c_binding
    implicit none

    integer nargs,numkeys,ios
    character(len=100), allocatable :: arg(:),keylist(:)
    character(len=100) psname(2),psname0(2),ofile,scaling(2)
    integer zeta,lm,degen
    integer nunits,nmol_1,nmol_2,nfeat_1,nfeat_2,natmax_1,natmax_2,nfeat0_1,nfeat0_2
    real*8, allocatable, target :: natoms_1(:),natoms_2(:), raw_PS_1(:),raw_PS_2(:),raw_PS0_1(:),raw_PS0_2(:)
    real*8, pointer :: PS0_1(:,:,:,:),PS0_2(:,:,:,:)
    real*8, pointer :: PS_1_lm(:,:,:,:),PS_2_lm(:,:,:,:)
    real*8, allocatable :: PS_1_fast_lm(:,:,:),PS_2_fast_lm(:,:,:)

    integer :: bytes,reals,i,j

    real*8, allocatable :: ker(:,:), ker_lm(:,:,:,:)
    logical :: hermiticity = .false.,readnext

    ! Get input arguments
    nargs = iargc()
    allocate(arg(nargs+1))
    do i=1,nargs
     call getarg(i,arg(i))
    enddo
    arg(nargs+1) = 'NULL'

    ! Parse these arguments
    zeta    = 1
    lm      = 0
    psname  = (/'',''/)
    psname0 = (/'',''/)
    scaling = (/'',''/)
    ofile   = ''
    numkeys = 7
    allocate(keylist(numkeys))
    keylist=(/'-z  ','-ps ','-ps0','-s  ','-o  ','-lm ','NULL'/)
    do i=1,nargs
     arg(i) = trim(adjustl(arg(i)))
     if (arg(i).eq.'-z') read(arg(i+1),*) zeta
     if (arg(i).eq.'-ps') then
      read(arg(i+1),*) psname(1)
      readnext = .true.
      do j=1,numkeys
       readnext = readnext.and.(arg(i+2).ne.trim(adjustl(keylist(j))))
      enddo
      if (readnext) then
       read(arg(i+2),*) psname(2)
      else
       psname(2) = psname(1)
      endif
      if (psname(1).eq.psname(2)) hermiticity=.true.
     endif
     if (arg(i).eq.'-ps0') then
      read(arg(i+1),*) psname0(1)
      readnext = .true.
      do j=1,numkeys
       readnext = readnext.and.(arg(i+2).ne.trim(adjustl(keylist(j))))
      enddo
      if (readnext) then
       read(arg(i+2),*) psname0(2)
      else
       psname0(2) = psname0(1)
      endif
     endif
     if (arg(i).eq.'-s') then
      read(arg(i+1),*) scaling(1)
      readnext = .true.
      do j=1,numkeys
       readnext = readnext.and.(arg(i+2).ne.trim(adjustl(keylist(j))))
      enddo
      if (readnext) then
       read(arg(i+2),*) scaling(2)
      else
       scaling(2) = scaling(1)
      endif
     endif
     if (arg(i).eq.'-o') read(arg(i+1),*) ofile
     if (arg(i).eq.'-lm') read(arg(i+1),*) lm
    enddo
    deallocate(keylist)

    ! Check for arguments that are required
    if (ofile.eq.'') stop 'ERROR: output file required!'
    if (psname(1).eq.'' .or. psname(2).eq.'') stop 'ERROR: power spectrum file(s) required!'
    if (scaling(1).eq.'' .or. scaling(2).eq.'') stop 'ERROR: scaling file(s) required!'

    ! Read in scaling file(s); if a file doesn't exist, then it is the number of 1s that has been entered
    do i=1,2
     open(unit=40,file=scaling(i),status='old',access='stream',form='unformatted',iostat=ios)
     if (ios.eq.0) then
      if (i.eq.1) then
       inquire(unit=40,size=bytes)
       reals = bytes/8
       allocate(natoms_1(reals))
       nmol_1 = reals
       read(40,pos=1) natoms_1
       close(40)
      else
       inquire(unit=40,size=bytes)
       reals = bytes/8
       allocate(natoms_2(reals))
       nmol_2 = reals
       read(40,pos=1) natoms_2
       close(40)
      endif
     else
      read(scaling(i),*) nunits
      if (i.eq.1) then
       allocate(natoms_1(nunits))
       natoms_1(:) = 1.d0
      else
       allocate(natoms_2(nunits))
       natoms_2(:) = 1.d0
      endif
     endif
    enddo

    ! Read in power spectrum file(s)
    degen = 2*lm + 1
    do i=1,2
     open(unit=41,file=psname(i),status='old',access='stream',form='unformatted')
     inquire(unit=41,size=bytes)
     reals = bytes/8
     if (i.eq.1) then
      allocate(raw_PS_1(reals))
      read(41,pos=1) raw_PS_1
      close(41)
      natmax_1 = maxval(natoms_1)
      nfeat_1 = reals / (nmol_1*natmax_1*degen)
      call C_F_POINTER(C_LOC(raw_PS_1),PS_1_lm,[nfeat_1,degen,natmax_1,nmol_1])
     else
      allocate(raw_PS_2(reals))
      read(41,pos=1) raw_PS_2
      close(41)
      natmax_2 = maxval(natoms_2)
      nfeat_2 = reals / (nmol_2*natmax_2*degen)
      call C_F_POINTER(C_LOC(raw_PS_2),PS_2_lm,[nfeat_2,degen,natmax_2,nmol_2])
     endif
    enddo

    ! Read in scalar power spectrum file(s) if necessary
    if (lm.gt.0 .and. zeta.gt.1) then
     if (psname0(1).eq.'' .or. psname0(2).eq.'') stop 'ERROR: scalar power spectrum file(s) required!'
     do i=1,2
      open(unit=41,file=psname0(i),status='old',access='stream',form='unformatted')
      inquire(unit=41,size=bytes)
      reals = bytes/8
      if (i.eq.1) then
       allocate(raw_PS0_1(reals))
       read(41,pos=1) raw_PS0_1
       close(41)
       nfeat0_1 = reals / (nmol_1*natmax_1)
       call C_F_POINTER(C_LOC(raw_PS0_1),PS0_1,[nfeat0_1,1,natmax_1,nmol_1])
      else
       allocate(raw_PS0_2(reals))
       read(41,pos=1) raw_PS0_2
       close(41)
       nfeat0_2 = reals / (nmol_2*natmax_2)
       call C_F_POINTER(C_LOC(raw_PS0_2),PS0_2,[nfeat0_2,1,natmax_2,nmol_2])
      endif
     enddo
    endif

    ! Build kernels
    if (lm.eq.0) then
     ker = do_scalar_kernel_rev(PS_1_lm,PS_2_lm,nmol_1,nmol_2,nfeat_1,nfeat_2,natmax_1,natmax_2,natoms_1,natoms_2,zeta,hermiticity)
    else
     if (zeta.eq.1) then
      ker_lm = do_linear_spherical_kernel_rev(PS_1_lm,PS_2_lm,nmol_1,nmol_2,nfeat_1, &
     &     nfeat_2,natmax_1,natmax_2,natoms_1,natoms_2,zeta,hermiticity,degen)
     else
      ker_lm = do_nonlinear_spherical_kernel_rev(PS_1_lm,PS_2_lm,PS0_1,PS0_2,nmol_1,nmol_2,nfeat_1,nfeat_2, &
     &     nfeat0_1,nfeat0_2,natmax_1,natmax_2,natoms_1,natoms_2,zeta,hermiticity,degen)

     endif

        if (allocated(PS_1_fast_lm)) deallocate(PS_1_fast_lm)
        if (allocated(PS_2_fast_lm)) deallocate(PS_2_fast_lm)

    endif

    ! Print kernel
    open(42,file=ofile,access='stream',form='unformatted')
     if (lm.eq.0) then
      write(42,pos=1) ker
     else
      write(42,pos=1) ker_lm
     endif
    close(42)

    if (allocated(ker)) deallocate(ker)
    if (allocated(ker_lm)) deallocate(ker_lm)
    deallocate(arg,natoms_1,natoms_2,raw_PS_1,raw_PS_2)

end program
