{ stdenv, fetchgit, python3, cmake, jq, libX11, libXext, zlib }:

stdenv.mkDerivation rec {
  pname = "swiftshader";
  version = "2021-01-17";

  src = fetchgit {
    url = "https://swiftshader.googlesource.com/SwiftShader";
    rev = "149733cead636de93d96c5c64f30168d5f6bb03f";
    sha256 = "1krhwybh98gp2rxbfc5gv7wjhsg3ncd2wqd8sizpy1kr7mr6c7av";
  };

  nativeBuildInputs = [ cmake python3 jq ];
  buildInputs = [ libX11 libXext zlib ];

  # Make sure we include the drivers and icd files in the output as the cmake
  # generated install command only puts in the spirv-tools stuff.
  installPhase = ''
    runHook preInstall

    #
    # Vulkan driver
    #
    vk_so_path="$out/lib/libvk_swiftshader.so"
    mkdir -p "$(dirname "$vk_so_path")"
    mv Linux/libvk_swiftshader.so "$vk_so_path"

    vk_icd_json="$out/share/vulkan/icd.d/vk_swiftshader_icd.json"
    mkdir -p "$(dirname "$vk_icd_json")"
    jq ".ICD.library_path = \"$vk_so_path\"" <Linux/vk_swiftshader_icd.json >"$vk_icd_json"

    #
    # GL driver
    #
    gl_so_path="$out/lib/libEGL.so"
    mkdir -p "$(dirname "$gl_so_path")"
    mv Linux/libEGL.so "$gl_so_path"

    gl_icd_json="$out/share/glvnd/egl_vendor.d/swiftshader.json"
    mkdir -p "$(dirname "$gl_icd_json")"
    cat >"$gl_icd_json" <<EOF
    {
      "file_format_version" : "1.0.0",
      "ICD" : {
          "library_path" : "$gl_so_path"
      }
    }
    EOF

    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description =
      "A high-performance CPU-based implementation of the Vulkan, OpenGL ES, and Direct3D 9 graphics APIs";
    homepage = "https://opensource.google/projects/swiftshader";
    license = licenses.asl20;
    # Should be possible to support Darwin by changing the install phase with
    # 's/Linux/Darwin/' and 's/so/dylib/' or something similar.
    platforms = [ "i686-linux" "x86_64-linux" "armv7l-linux" "mipsel-linux" ];
    maintainers = with maintainers; [ expipiplus1 ];
  };
}
