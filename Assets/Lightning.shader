// Converted this shader by sqrt_1 (https://www.shadertoy.com/view/4scGWj)
Shader "Unlit/Lightning"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
			float3 random3(float3 c) {
				float j = 4096.0*sin(dot(c, float3(17.0, 59.4, 15.0)));
				float3 r;
				r.z = frac(512.0*j);
				j *= .125;
				r.x = frac(512.0*j);
				j *= .125;
				r.y = frac(512.0*j);
				return r - 0.5;
			}

			/* skew constants for 3d simplex functions */
			static const float F3 = 0.3333333;
			static const float G3 = 0.1666667;

			/* 3d simplex noise */
			float simplex3d(float3 p) {
				/* 1. find current tetrahedron T and it's four vertices */
				/* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
				/* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

				/* calculate s and x */
				float3 s = floor(p + dot(p, float3(F3, F3, F3)));
				float3 x = p - s + dot(s, float3(G3, G3, G3));

				/* calculate i1 and i2 */
				float3 e = step(float3(0.0, 0.0, 0.0), x - x.yzx);
				float3 i1 = e * (1.0 - e.zxy);
				float3 i2 = 1.0 - e.zxy*(1.0 - e);

				/* x1, x2, x3 */
				float3 x1 = x - i1 + G3;
				float3 x2 = x - i2 + 2.0*G3;
				float3 x3 = x - 1.0 + 3.0*G3;

				/* 2. find four surflets and store them in d */
				float4 w, d;

				/* calculate surflet weights */
				w.x = dot(x, x);
				w.y = dot(x1, x1);
				w.z = dot(x2, x2);
				w.w = dot(x3, x3);

				/* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
				w = max(0.6 - w, 0.0);

				/* calculate surflet components */
				d.x = dot(random3(s), x);
				d.y = dot(random3(s + i1), x1);
				d.z = dot(random3(s + i2), x2);
				d.w = dot(random3(s + 1.0), x3);

				/* multiply d by w^4 */
				w *= w;
				w *= w;
				d *= w;

				/* 3. return the sum of the four surflets */
				return dot(d, float4(52.0, 52.0, 52.0, 52.0));
			}

			float noise(float3 m) {
				return   0.5333333*simplex3d(m)
					+ 0.2666667*simplex3d(2.0*m)
					+ 0.1333333*simplex3d(4.0*m)
					+ 0.0666667*simplex3d(8.0*m);
			}

            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv.xy;// fragCoord.xy / iResolution.xy;
				uv = uv * 2. - 1.;

				float2 p = i.uv;// fragCoord.xy / iResolution.x;
				float3 p3 = float3(p, _Time.y*0.4);

				float intensity = noise(float3(p3*12.0 + 12.0));

				float t = clamp((uv.x * -uv.x * 0.16) + 0.15, 0., 1.);
				float y = abs(intensity * -t + uv.y);

				float g = pow(y, 0.2);

				float3 col = float3(1.70, 1.48, 1.78);
				col = col * -g + col;
				col = col * col;
				col = col * col;

				//fragColor.rgb = col;
				//fragColor.w = 1.;
				return float4(col, 1);
            }
            ENDCG
        }
    }
}
